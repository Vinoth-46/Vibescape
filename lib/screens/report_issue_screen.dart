import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:io'; // For Platform check
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _deviceInfoController = TextEditingController();
  
  // TODO: REPLACE THIS WITH YOUR FORMSPREE ENDPOINT
  // 1. Go to https://formspree.io/
  // 2. Sign up (Free)
  // 3. Create a New Form
  // 4. Copy the Endpoint URL (e.g., https://formspree.io/f/xyza...)
  static const String _formspreeEndpoint = "https://formspree.io/f/mjgwdrwz";

  String _issueType = 'Bug Report';
  final List<String> _issueTypes = ['Bug Report', 'Feature Request', 'Feedback', 'Other'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String info = "Unknown Device";

    try {
      if (kIsWeb) {
        final WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
        info = "Web: ${webInfo.browserName.name} (Platform: ${webInfo.platform})";
      } else if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        info = "Android: ${androidInfo.manufacturer} ${androidInfo.model} (SDK ${androidInfo.version.sdkInt})";
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        info = "iOS: ${iosInfo.utsname.machine} (${iosInfo.systemName} ${iosInfo.systemVersion})";
      } else if (Platform.isWindows) {
        final WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
        info = "Windows: ${windowsInfo.computerName} (Major ${windowsInfo.majorVersion})";
      }
    } catch (e) {
      info = "Could not retrieve device info: $e";
    }

    if (mounted) {
      setState(() {
        _deviceInfoController.text = info;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_formspreeEndpoint.contains("YOUR_FORM_ID_HERE")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Developer: Please configure Formspree ID in code.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_formspreeEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text,
          'subject': "$_issueType - ISAI Music Player",
          'issue_type': _issueType,
          'device_info': _deviceInfoController.text,
          'message': _descriptionController.text,
        }),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Report sent successfully! Thank you.")),
          );
          Navigator.pop(context);
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to send. Error: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report an Issue"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "We value your feedback. Please provide as much detail as possible.",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _issueType,
                      decoration: const InputDecoration(
                        labelText: "Issue Type",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category, color: Colors.teal),
                      ),
                      items: _issueTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) => setState(() => _issueType = value!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Your Email (Optional)",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email, color: Colors.teal),
                        hintText: "If you want a reply",
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _deviceInfoController,
                      decoration: const InputDecoration(
                        labelText: "Device Information",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_android, color: Colors.teal),
                        filled: true,
                        fillColor: Colors.black12,
                      ),
                      readOnly: true, // Auto-filled
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                        hintText: "Describe what happened, steps to reproduce, etc.",
                      ),
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please describe the issue';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _sendReport,
                      icon: const Icon(Icons.send),
                      label: const Text("Submit Report"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
