import 'package:intl/intl.dart';

class AppValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Improved regular expression for email validation
    String pattern =
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    // Additional check to ensure there are no consecutive dots in the domain
    if (value.contains('..')) {
      return 'Enter a valid email address';
    }

    return null;
  }


  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    String trimmedValue = value.trim();

    // Check if it is exactly 10 digits
    String pattern = r'^\d{10}$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(trimmedValue)) {
      return 'Enter a valid 10-digit phone number';
    }

    // Check if the first digit is between 1 and 5
    if (int.parse(trimmedValue[0]) >= 1 && int.parse(trimmedValue[0]) <= 5) {
      return 'Phone number cannot start with digits 1 to 5';
    }

    return null;
  }



  static String? validateEmailOrPhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }

    bool containsNonNumeric = value.runes.any((rune) => !RegExp(r'\d').hasMatch(String.fromCharCode(rune)));

    if (containsNonNumeric) {
      String emailPattern =
          r'^[\w\.-]+@[a-zA-Z\d\.-]+\.[a-zA-Z]{2,}$';
      RegExp emailRegex = RegExp(emailPattern);
      if (!emailRegex.hasMatch(value)) {
        return 'Enter a valid email address';
      }
    } else {
      String phonePattern = r'^\d{6,14}$';
      RegExp phoneRegex = RegExp(phonePattern);
      if (!phoneRegex.hasMatch(value)) {
        return 'Enter a valid 10-digit phone number';
      }
    }

    return null;
  }

  static String? validateDropdown(dynamic value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? validateText(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? validateOTP(String? value) {
    if (value == null || value.length < 6) {
      return 'Please Enter a valid OTP';
    }
    return null;
  }
  static String? validatePassword(String? value) {
    if (value == null || value.length < 8) {
      return 'Please Enter a 8 digit password';
    }
    return null;
  }

  static String? validateYear(String? value) {
    if (value == null || value.length < 4) {
      return 'Enter a date in the format YYYY';
    }
    return null;
  }


  static String? validateAge(String? value) {
    if (value == null || int.parse(value) > 200 || int.parse(value) <= 15) {
      return 'Enter a valid age';
    }
    return null;
  }

  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    final RegExp dateRegex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
    if (!dateRegex.hasMatch(value)) {
      return 'Enter a date in the format DD-MM-YYYY';
    }
    try {
      DateFormat('dd-MM-yyyy').parseStrict(value);
    } catch (e) {
      return 'Enter a valid date';
    }

    return null;
  }


  static String? validateGoogleMapsLink(String? value) {
    // Regular expression pattern for both full Google Maps URLs and shortened goo.gl links
    const pattern = r'^(https?:\/\/)?(www\.)?(maps\.google\.[a-z]+|goo\.gl)\/(maps\/)?[^\s]+$';
    final regExp = RegExp(pattern);

    if (value == null || value.isEmpty) {
      return 'Please enter a valid Google Maps link';
    } else if (!regExp.hasMatch(value)) {
      return 'Please enter a valid Google Maps URL';
    }

    return null;  // No error
  }



}
