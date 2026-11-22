import 'package:flutter/material.dart';
import '../utils/app_styles.dart';

class WindowContainer extends StatelessWidget {
  final double? height;
  final Widget child;
  final Color? borderColor;
  final Color? winColor;

  const WindowContainer({
    super.key,
    this.height,
    required this.child,
    this.borderColor,
    this.winColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: winColor ?? AppTheme.window_background,
        border: Border.all(color: borderColor ?? AppTheme.lessWhite, width: 1),
      ),
      child: child,
    );
  }
}



class SubWindowContainer extends StatelessWidget {
  final double height;
  final Widget child;

  const SubWindowContainer({
    super.key,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 220, 90, 90), // Fondo
                  borderRadius: BorderRadius.circular(20), // Bordes redondeados
                  border: Border.all(color: Colors.white, width: 2),
                ),
      child: child,
    );
  }
}


ElevatedButton windowActionButton(Function() action,IconData icon){
    return ElevatedButton(
      onPressed: action,
      style: 
        ElevatedButton.styleFrom(
          backgroundColor: AppTheme.background, 
          foregroundColor: Colors.white,
          side: BorderSide(color: AppTheme.lessWhite, width: 1, ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero,),),
          child: Icon(icon,color: AppTheme.lessWhite),
        );
}





