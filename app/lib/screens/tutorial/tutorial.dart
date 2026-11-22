import 'package:flutter/material.dart';
import '../about/about_fn.dart';
// Para Clipboard




Widget tutorialScreen () {
  return Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              SectionHeader("To fragment"),
              listNumb("1. ", "Select target file to fragment"),
              listNumb("2. ", "Select the places where you want the pieces to be"),
              //listNumb("    ", " [!] Do not move them or place the pieces in the same location when recomposing"),
              listNumb("3. ", "Select file encryption type: High is recommended"),
              listNumb("4. ", "Select the number of pieces; the default is fine"),
              listNumb("5. ", "Write a password, you'll need it for recomposing"),
              listNumb("6. ", "Press Slys!"),
              SizedBox(height: 10,),
              SectionHeader("To recompose"),
              listNumb("1. ", "Select a seed from the list, or add the one you saved"),
              listNumb("2. ", "Write the password"),
              listNumb("3. ", "Select the folder where the pieces are"),
              listNumb("4. ", "Press Recompose!"),
              listNumb("5. ", "If no default folder is set in Settings, Slys asks where to put the rebuilt file"),
            ]);
}