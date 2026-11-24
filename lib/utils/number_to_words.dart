class NumberToWords {
  static const List<String> _units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];

  static const List<String> _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  static String _convertThreeDigits(int n) {
    String result = '';
    if (n >= 100) {
      result += '${_units[n ~/ 100]} Hundred';
      n %= 100;
      if (n > 0) result += ' and ';
    }
    if (n >= 20) {
      result += _tens[n ~/ 10];
      if (n % 10 > 0) {
        result += ' ${_units[n % 10]}';
      }
    } else if (n > 0) {
      result += _units[n];
    }
    return result;
  }

  /// Converts a number to Indian Currency words
  /// Example: 87792 -> "Eighty Seven Thousand Seven Hundred and Ninety Two Rupees only"
  static String convert(double amount) {
    if (amount == 0) return 'Zero Rupees only';

    final int rupees = amount.floor();
    final int paise = ((amount - rupees) * 100).round();

    if (rupees == 0 && paise > 0) {
      return '${_convertIndianNumber(paise)} Paise only';
    }

    String result = _convertIndianNumber(rupees);
    result = '$result Rupees';

    if (paise > 0) {
      result += ' and ${_convertIndianNumber(paise)} Paise';
    }

    result += ' only';
    return result;
  }

  static String _convertIndianNumber(int n) {
    if (n == 0) return 'Zero';

    String result = '';

    // Crores (1,00,00,000)
    final int crores = n ~/ 10000000;
    n %= 10000000;
    if (crores > 0) {
      result += '${_convertIndianNumber(crores)} Crore ';
    }

    // Lakhs (1,00,000)
    final int lakhs = n ~/ 100000;
    n %= 100000;
    if (lakhs > 0) {
      result += '${_convertIndianNumber(lakhs)} Lakh ';
    }

    // Thousands (1,000)
    final int thousands = n ~/ 1000;
    n %= 1000;
    if (thousands > 0) {
      result += '${_convertThreeDigits(thousands)} Thousand ';
    }

    // Hundreds and below
    if (n > 0) {
      if (n >= 100) {
        result += '${_units[n ~/ 100]} Hundred ';
        n %= 100;
        if (n > 0) {
          result += 'and ';
        }
      }
      if (n >= 20) {
        result += _tens[n ~/ 10];
        if (n % 10 > 0) {
          result += ' ${_units[n % 10]}';
        }
      } else if (n > 0) {
        result += _units[n];
      }
    }

    return result.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
