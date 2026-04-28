import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Rive inputs

  bool _obscureText = true;

  //Cerebor de la logica de la animacion
  StateMachineController? _controller;

  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  //2.1 Variables para el seguimiento de los ojos
  SMINumber? _numLook;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  // 1.1. crear variables para FocusNode
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  Timer? _typingDebounce;

  // 4.1 Controllers para manipular texto
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  // 4.2 errores para mostar en UI
  String? emailError;
  String? passwordError;

  // 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // mínimo 8, una mayúscula, una minúscula, un dígito y un especial
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  void _onLogin() {
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    // recalcurlar erroes
    final emailUIError = isValidEmail(email) ? null : 'Email invalid';
    final passwordUIError = isValidPassword(password)
        ? null
        : 'Password invalid';

    setState(() {
      emailError = emailUIError;
      passwordError = passwordUIError;
    });

    //4.6
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    if (emailUIError == null && passwordUIError == null) {
      //login ok
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }

    // 5.1 validacion de la animacion
  }

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        if (_isHandsUp != null) {
          //manos abajo
          _isHandsUp?.change(false);
          _numLook?.value = 50.0;
        }
      }
    });
    _passwordFocusNode.addListener(() {
      _isHandsUp?.change(_passwordFocusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFD6E2E8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              children: [
                SizedBox(
                  width: size.width,
                  height: size.height * 0.4,
                  child: RiveAnimation.asset(
                    'assets/animated_login_character.riv',
                    stateMachines: ["Login Machine"],
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        "Login Machine",
                      );
                      if (_controller == null) return;
                      artboard.addController(_controller!);

                      _isChecking =
                          _controller!.findSMI('isChecking') as SMIBool;
                      _isHandsUp = _controller!.findSMI('isHandsUp') as SMIBool;
                      _numLook = _controller!.findSMI('numLook') as SMINumber;
                      _trigSuccess =
                          _controller!.findSMI('trigSuccess') as SMITrigger;
                      _trigFail =
                          _controller!.findSMI('trigFail') as SMITrigger;
                    },
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  //4.8
                  controller: emailCtrl,
                  focusNode:
                      _emailFocusNode, // 1.3. asignar el FocusNode al TextField
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      _isHandsUp!.change(false);
                    }
                    if (_isChecking == null) return;
                    _isChecking!.change(true);
                    //2.4 implementar logica
                    //Ajustes son del 0 al 100. 80 medida de calibracion
                    // Clamp es un rango (abrazadera)
                    final double look = (value.length / 80.0 * 100.0).clamp(
                      0,
                      100,
                    );
                    _numLook?.value = look;
                    _typingDebounce?.cancel();
                    _typingDebounce = Timer(const Duration(seconds: 3), () {
                      //si se cierra la pantalla, quita el contador
                      if (!mounted) return;
                      _isChecking?.change(false);
                    });
                  },
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    //4.9 Mostrar error
                    errorText: emailError,
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordCtrl,
                  focusNode:
                      _passwordFocusNode, // 1.4. asignar el FocusNode al TextField
                  onChanged: (value) {
                    if (_isChecking != null) {
                      //_isChecking!.change(false);
                    }
                    if (_isHandsUp == null) return;
                    //_isHandsUp!.change(true);
                  },
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    //4.10 Mostrar error
                    errorText: passwordError,
                    hintText: 'Contraseña',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          // Usamos "=" para asignar el nuevo valor
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // Texto de olvide la contraseña
                SizedBox(
                  width: size.width,
                  child: const Text(
                    '¿Forgot your password?',
                    textAlign: TextAlign.right,
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
                SizedBox(height: 10),
                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  onPressed: _onLogin,
                  color: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(
                  width: size.width,
                  child: Row(
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //liberar memorias al salir de la pantalla
  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }
}
