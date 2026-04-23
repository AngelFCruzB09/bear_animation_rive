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

  @override
  void initState(){
    super.initState();
    _emailFocusNode.addListener((){
      if (_emailFocusNode.hasFocus){
        if (_isHandsUp != null){
          //manos abajo
          _isHandsUp?.change(false);
          _numLook?.value = 50.0;
        }
      }
    });
    _passwordFocusNode.addListener((){
      _isHandsUp?.change(_passwordFocusNode.hasFocus);
    });

  }

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFD6E2E8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsGeometry.symmetric(horizontal: 40.0),
          child: Column(
          children: [
            SizedBox(
              width: size.width,
              height: size.height * 0.4,
              child: RiveAnimation.asset('assets/animated_login_character.riv',
              stateMachines: ["Login Machine"],
              onInit: (artboard){
                _controller = StateMachineController.fromArtboard(
                  artboard,
                  "Login Machine",

                );
                if (_controller == null) return;
                artboard.addController(_controller!);

                _isChecking = _controller!.findSMI('isChecking') as SMIBool;
                _isHandsUp =  _controller!.findSMI('isHandsUp') as SMIBool;
                _numLook = _controller!.findSMI('numLook') as SMINumber;
                _trigSuccess = _controller!.findSMI('trigSuccess') as SMITrigger;
                _trigFail = _controller!.findSMI('trigFail') as SMITrigger;
              },
              )
          
            ),
            const SizedBox(height: 10,),
            TextField(
                focusNode: _emailFocusNode, // 1.3. asignar el FocusNode al TextField
                onChanged: (value){
                  if (_isHandsUp != null){
                    _isHandsUp!.change(false);
                  }
                  if (_isChecking == null) return;
                    _isChecking!.change(true);
                  //2.4 implementar logica
                  //Ajustes son del 0 al 100. 80 medida de calibracion
                  // Clamp es un rango (abrazadera)
                  final double look = (value.length / 80.0 * 100.0).clamp(0, 100);
                  _numLook?.value = look;
                  _typingDebounce?.cancel();
                  _typingDebounce = Timer(const Duration(seconds: 3), (){
                    //si se cierra la pantalla, quita el contador 
                    if (!mounted) return;
                    _isChecking?.change(false);
                });
                },
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email),
                  hintText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              focusNode: _passwordFocusNode, // 1.4. asignar el FocusNode al TextField
              onChanged: (value) {
                  if (_isChecking != null) {
                    //_isChecking!.change(false);
                  }
                  if (_isHandsUp == null) return;
                  //_isHandsUp!.change(true);
                },
              obscureText: _obscureText,
              decoration: InputDecoration(
                hintText: 'Contraseña',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)
                ) ,
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
          
            

          ],

        ))));
        



        
  }
  //liberar memorias al salir de la pantalla
  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }
}

  