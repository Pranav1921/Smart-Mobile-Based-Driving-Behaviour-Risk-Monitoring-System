import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:intl/intl.dart';
import '../core/theme/hardware_theme.dart';
import '../core/theme/framer_motion.dart';
import '../models/transaction_model.dart';
import '../providers/trip_provider.dart';
import '../services/haptic_service.dart';

class UpiPaymentModal extends StatefulWidget {
  final String payeeName;
  final String payeeUpiId;
  final double defaultAmount;
  final PaymentCategory category;

  const UpiPaymentModal({
    super.key,
    required this.payeeName,
    required this.payeeUpiId,
    this.defaultAmount = 100.0,
    this.category = PaymentCategory.fuel,
  });

  static void show(
    BuildContext context, {
    required String payeeName,
    required String payeeUpiId,
    double defaultAmount = 100.0,
    PaymentCategory category = PaymentCategory.fuel,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpiPaymentModal(
        payeeName: payeeName,
        payeeUpiId: payeeUpiId,
        defaultAmount: defaultAmount,
        category: category,
      ),
    );
  }

  @override
  State<UpiPaymentModal> createState() => _UpiPaymentModalState();
}

class _UpiPaymentModalState extends State<UpiPaymentModal> {
  // Step 1: Input details, Step 2: Enter UPI PIN, Step 3: Success Receipt
  int _currentStep = 1;
  late TextEditingController _amountController;
  final TextEditingController _noteController = TextEditingController();
  late PaymentCategory _selectedCategory;
  String _selectedAccount = "State Bank of India (****4821)";
  String _pinCode = "";
  bool _isProcessing = false;
  PaymentTransaction? _completedTxn;
  late ConfettiController _confettiController;

  final List<double> _quickChips = [50.0, 100.0, 200.0, 500.0, 1000.0];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.defaultAmount.toInt().toString());
    _selectedCategory = widget.category;
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onProceedToPin() {
    final double? amt = double.tryParse(_amountController.text.trim());
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount"), backgroundColor: Colors.redAccent),
      );
      return;
    }
    HapticService.selectionClick();
    setState(() {
      _currentStep = 2;
      _pinCode = "";
    });
  }

  void _onKeypadTap(String value) {
    HapticService.lightImpact();
    if (_isProcessing) return;

    if (value == "back") {
      if (_pinCode.isNotEmpty) {
        setState(() {
          _pinCode = _pinCode.substring(0, _pinCode.length - 1);
        });
      }
      return;
    }

    if (_pinCode.length < 4) {
      setState(() {
        _pinCode += value;
      });

      if (_pinCode.length == 4) {
        _processPayment();
      }
    }
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    HapticService.heavyImpact();

    await Future.delayed(const Duration(milliseconds: 1100));

    final tripProv = Provider.of<TripProvider>(context, listen: false);
    final double amount = double.tryParse(_amountController.text.trim()) ?? widget.defaultAmount;
    final String note = _noteController.text.trim();

    final txn = await tripProv.makeUpiPayment(
      title: widget.payeeName,
      subtitle: "UPI to ${widget.payeeUpiId}",
      amount: amount,
      category: _selectedCategory,
      upiId: widget.payeeUpiId,
      notes: note.isNotEmpty ? note : null,
      paymentMethod: _selectedAccount,
    );

    _confettiController.play();
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _completedTxn = txn;
        _currentStep = 3;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F2EB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset > 0 ? bottomInset + 16 : 28),
      child: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _currentStep == 1
                ? _buildStep1Amount()
                : (_currentStep == 2 ? _buildStep2UpiPin() : _buildStep3SuccessReceipt()),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFF10B981),
                Color(0xFF00FF9D),
                Colors.amber,
                Colors.cyanAccent,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // STEP 1: Enter Amount & Details
  // ----------------------------------------------------
  Widget _buildStep1Amount() {
    return Column(
      key: const ValueKey(1),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top drag handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: const Color(0xFF8C827A).withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 16),

        // Payee Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: HardwarePalette.matrixBorderLight),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF23201C).withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFECFDF5),
                child: Text(
                  widget.payeeName.isNotEmpty ? widget.payeeName[0].toUpperCase() : "P",
                  style: GoogleFonts.outfit(
                    color: HardwarePalette.signalEmerald,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.payeeName,
                            style: GoogleFonts.outfit(color: HardwarePalette.silkscreenDark, fontWeight: FontWeight.w800, fontSize: 14.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: Color(0xFF0284C7), size: 15),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.payeeUpiId,
                      style: GoogleFonts.spaceGrotesk(color: HardwarePalette.silkscreenSubtle, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "UPI PAY",
                  style: GoogleFonts.spaceGrotesk(color: const Color(0xFF0284C7), fontSize: 9.5, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Amount Field
        Center(
          child: Column(
            children: [
              Text("ENTER AMOUNT", style: GoogleFonts.spaceGrotesk(color: const Color(0xFF5E574E), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "₹",
                    style: GoogleFonts.outfit(color: const Color(0xFF059669), fontSize: 36, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 4),
                  IntrinsicWidth(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: GoogleFonts.outfit(color: const Color(0xFF23201C), fontSize: 38, fontWeight: FontWeight.w900),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "0",
                        hintStyle: TextStyle(color: Color(0xFF9E9589)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Quick Amount Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _quickChips.map((amt) {
              return FramerPressable(
                onTap: () {
                  HapticService.selectionClick();
                  _amountController.text = amt.toInt().toString();
                  setState(() {});
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HardwarePalette.matrixBorderLight),
                  ),
                  child: Text(
                    "+₹${amt.toInt()}",
                    style: GoogleFonts.spaceGrotesk(color: HardwarePalette.signalEmerald, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 18),

        // Category Selector
        Text("Payment Category", style: GoogleFonts.outfit(color: const Color(0xFF23201C), fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _categoryChip(PaymentCategory.fuel, "⛽ Petrol / Fuel"),
              _categoryChip(PaymentCategory.food, "☕ Chai & Food"),
              _categoryChip(PaymentCategory.maintenance, "🛠️ Maintenance"),
              _categoryChip(PaymentCategory.toll, "🛣️ Fastag / Toll"),
              _categoryChip(PaymentCategory.parking, "🅿️ Parking"),
              _categoryChip(PaymentCategory.upiTransfer, "🔄 General UPI"),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Debiting Account Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HardwarePalette.matrixBorderLight),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_rounded, color: Color(0xFF0284C7), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("DEBIT FROM", style: GoogleFonts.spaceGrotesk(color: HardwarePalette.silkscreenSubtle, fontSize: 9.5, fontWeight: FontWeight.w700)),
                    Text(_selectedAccount, style: GoogleFonts.plusJakartaSans(color: HardwarePalette.silkscreenDark, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const Icon(Icons.lock_outline_rounded, color: HardwarePalette.signalEmerald, size: 16),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Proceed Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _onProceedToPin,
            style: ElevatedButton.styleFrom(
              backgroundColor: HardwarePalette.signalEmerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("PROCEED TO PAY", style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryChip(PaymentCategory cat, String label) {
    final isSelected = _selectedCategory == cat;
    return FramerPressable(
      onTap: () => setState(() => _selectedCategory = cat),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? HardwarePalette.signalEmerald : HardwarePalette.matrixBorderLight),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? HardwarePalette.signalEmerald : HardwarePalette.silkscreenDark,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // STEP 2: Authentic UPI PIN Input Screen
  // ----------------------------------------------------
  Widget _buildStep2UpiPin() {
    final double amount = double.tryParse(_amountController.text.trim()) ?? widget.defaultAmount;

    return Column(
      key: const ValueKey(2),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bank and Payee Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => setState(() => _currentStep = 1),
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF23201C), size: 20),
            ),
            Column(
              children: [
                Text("ENTER 4-DIGIT UPI PIN", style: GoogleFonts.outfit(color: const Color(0xFF23201C), fontSize: 13.5, fontWeight: FontWeight.w800)),
                Text("State Bank of India", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF5E574E), fontSize: 10.5, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(width: 40),
          ],
        ),

        const SizedBox(height: 14),

        // Transaction Summary Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HardwarePalette.matrixBorderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Paying to", style: GoogleFonts.spaceGrotesk(color: HardwarePalette.silkscreenSubtle, fontSize: 9.5)),
                  Text(widget.payeeName, style: GoogleFonts.plusJakartaSans(color: HardwarePalette.silkscreenDark, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
              Text(
                "₹${amount.toStringAsFixed(0)}",
                style: GoogleFonts.outfit(color: HardwarePalette.signalEmerald, fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 4 Dot Indicators
        if (_isProcessing)
          Column(
            children: [
              const SizedBox(height: 10),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF059669)),
              ),
              const SizedBox(height: 12),
              Text("Authorizing Bank & NPCI Payment...", style: GoogleFonts.spaceGrotesk(color: const Color(0xFF5E574E), fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFilled = index < _pinCode.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? const Color(0xFF059669) : Colors.transparent,
                  border: Border.all(
                    color: isFilled ? const Color(0xFF059669) : const Color(0xFF8C827A),
                    width: 2,
                  ),
                  boxShadow: isFilled
                      ? [
                          BoxShadow(
                            color: const Color(0xFF059669).withOpacity(0.4),
                            blurRadius: 10,
                          ),
                        ]
                      : [],
                ),
              );
            }),
          ),

        const SizedBox(height: 24),

        // Tactical Numeric Keypad
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              _keypadRow(["1", "2", "3"]),
              const SizedBox(height: 12),
              _keypadRow(["4", "5", "6"]),
              const SizedBox(height: 12),
              _keypadRow(["7", "8", "9"]),
              const SizedBox(height: 12),
              _keypadRow(["clear", "0", "back"]),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Security footer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security_rounded, color: Color(0xFF5E574E), size: 13),
            const SizedBox(width: 5),
            Text(
              "256-BIT ENCRYPTED UPI PAYMENT GATEWAY",
              style: GoogleFonts.spaceGrotesk(color: const Color(0xFF5E574E), fontSize: 9.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }

  Widget _keypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key == "clear") {
          return SizedBox(
            width: 70,
            height: 48,
            child: FramerPressable(
              onTap: () {
                HapticService.selectionClick();
                setState(() => _pinCode = "");
              },
              child: Center(
                child: Text("CLEAR", style: GoogleFonts.spaceGrotesk(color: const Color(0xFF5E574E), fontSize: 10.5, fontWeight: FontWeight.w800)),
              ),
            ),
          );
        }

        if (key == "back") {
          return SizedBox(
            width: 70,
            height: 48,
            child: FramerPressable(
              onTap: () => _onKeypadTap("back"),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: HardwarePalette.matrixBorderLight),
                ),
                child: Center(
                  child: Icon(Icons.backspace_outlined, color: HardwarePalette.silkscreenDark, size: 18),
                ),
              ),
            ),
          );
        }

        return SizedBox(
          width: 70,
          height: 48,
          child: FramerPressable(
            onTap: () => _onKeypadTap(key),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: HardwarePalette.matrixBorderLight),
              ),
              child: Center(
                child: Text(
                  key,
                  style: GoogleFonts.outfit(color: HardwarePalette.silkscreenDark, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ----------------------------------------------------
  // STEP 3: Animated Success Receipt
  // ----------------------------------------------------
  Widget _buildStep3SuccessReceipt() {
    final txn = _completedTxn;
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(txn?.timestamp ?? DateTime.now());

    return Column(
      key: const ValueKey(3),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),

        // Glowing Success Check Icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: HardwarePalette.signalEmerald.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: HardwarePalette.signalEmerald, width: 2),
            boxShadow: [
              BoxShadow(
                color: HardwarePalette.signalEmerald.withOpacity(0.3),
                blurRadius: 20,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.check_rounded, color: HardwarePalette.signalEmerald, size: 36),
          ),
        ),

        const SizedBox(height: 14),

        Text("Payment Successful", style: GoogleFonts.outfit(color: const Color(0xFF23201C), fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          "₹${(txn?.amount ?? 0).toStringAsFixed(0)}",
          style: GoogleFonts.outfit(color: HardwarePalette.signalEmerald, fontSize: 32, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          "Paid to ${txn?.title ?? widget.payeeName}",
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF5E574E), fontSize: 12, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 18),

        // Receipt breakdown card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: HardwarePalette.matrixBorderLight),
          ),
          child: Column(
            children: [
              _receiptRow("UPI Reference (UTR)", txn?.utrNumber ?? "423985102941"),
              Divider(color: HardwarePalette.matrixBorderLight, height: 16),
              _receiptRow("Payee UPI ID", txn?.upiId ?? widget.payeeUpiId),
              Divider(color: HardwarePalette.matrixBorderLight, height: 16),
              _receiptRow("Date & Time", dateStr),
              Divider(color: HardwarePalette.matrixBorderLight, height: 16),
              _receiptRow("Debited From", txn?.paymentMethod ?? "SBI (****4821)"),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/history');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF8C827A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text("VIEW IN HISTORY", style: GoogleFonts.spaceGrotesk(color: const Color(0xFF23201C), fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: Text("DONE", style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _receiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.spaceGrotesk(color: HardwarePalette.silkscreenSubtle, fontSize: 11, fontWeight: FontWeight.w600)),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.spaceGrotesk(color: HardwarePalette.silkscreenDark, fontSize: 11, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
