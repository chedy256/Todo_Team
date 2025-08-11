import 'package:flutter/material.dart';
import 'package:project/controllers/auth_controller.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});
  @override
  State<StatefulWidget> createState() => _EmailScreenStates();
}

class _EmailScreenStates extends State<EmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? validateEmail(String? email) {
    final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(email ?? '') ||
        (email != null &&
            (email.isEmpty || email.contains('=') || email.contains(' ')))) {
      return 'Entrez un email valide ';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 30),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                colors: [
                  Colors.blueAccent.shade700,
                  Colors.blue,
                  Colors.lightBlueAccent.shade100,
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: 120,
            child: Text(
              '''Se connecter\nou S'inscrire''',
              style: TextStyle(
                color: Colors.black,
                fontSize: 36,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Positioned(
            left: 5,
            right: 5,
            top: 250,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter votre address email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: validateEmail,
                  ),
                ),
              ),

          ),
          ),
          Positioned(
            right: 24,
            left: 24,
            top: 750,
            child: ElevatedButton.icon(
              onPressed: () => {
                if(_formKey.currentState!.validate()){
                  AuthController.checkEmail(_emailController.text, context)
                }
              },
              icon: Icon(Icons.arrow_forward, color: Colors.white),
              label: Text(
                'Suivant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent.shade700,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
