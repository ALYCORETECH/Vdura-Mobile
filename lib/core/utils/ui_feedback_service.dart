import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

class UiFeedbackService {

  void showLoader() {
    BotToast.showLoading(
      clickClose: false,
      allowClick: false,
      backgroundColor: Colors.black26,
    );
  }

  void hideLoader() {
    BotToast.closeAllLoading();
  }

  void showSuccess(String message) {
    BotToast.showText(
      text: message,
      contentColor: Colors.green.shade700,
      textStyle: const TextStyle(color: Colors.white),
    );
  }

  void showError(String message) {
    BotToast.showText(
      text: message,
      contentColor: Colors.red.shade700,
      textStyle: const TextStyle(color: Colors.white),
    );
  }

  void showInfo(String message) {
    BotToast.showText(text: message);
  }
}