import 'package:flutter/material.dart';
import '../theme/lysen_theme.dart';

/// 3-Step Guided Key Rotation Wizard Modal.
class KeyRotationWizardModal extends StatefulWidget {
  const KeyRotationWizardModal({super.key});

  @override
  State<KeyRotationWizardModal> createState() => _KeyRotationWizardModalState();
}

class _KeyRotationWizardModalState extends State<KeyRotationWizardModal> {
  int _currentStep = 0;
  String _selectedAlgo = "Ed25519 (Recommended)";
  bool _useHardwareEnclave = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LysenTheme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: LysenTheme.borderGlass, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Key Rotation Wizard (${_currentStep + 1}/3)",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LysenTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: LysenTheme.textMuted, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: LysenTheme.borderGlass),
            const SizedBox(height: 12),

            if (_currentStep == 0) ...[
              const Text("Step 1: Select Key Algorithm Specification", style: TextStyle(color: LysenTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              _RadioOptionTile(
                title: "Ed25519 (Fast & High Security)",
                value: "Ed25519 (Recommended)",
                selectedValue: _selectedAlgo,
                onSelect: (v) => setState(() => _selectedAlgo = v),
              ),
              const SizedBox(height: 8),
              _RadioOptionTile(
                title: "ECDSA secp256r1 (FIPS 186-4)",
                value: "ECDSA P-256",
                selectedValue: _selectedAlgo,
                onSelect: (v) => setState(() => _selectedAlgo = v),
              ),
            ] else if (_currentStep == 1) ...[
              const Text("Step 2: Key Enclave & Passphrase Protection", style: TextStyle(color: LysenTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              SwitchListTile(
                activeTrackColor: LysenTheme.taupeAcc,
                activeThumbColor: LysenTheme.silverAcc,
                title: const Text("Store in Hardware Enclave", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 13)),
                subtitle: const Text("Use iOS Keychain / Android Keystore", style: TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
                value: _useHardwareEnclave,
                onChanged: (v) => setState(() => _useHardwareEnclave = v),
              ),
            ] else ...[
              const Text("Step 3: Confirm & Bind X.509 Certificate", style: TextStyle(color: LysenTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF070505),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Algorithm: $_selectedAlgo", style: const TextStyle(color: LysenTheme.silverAcc, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Enclave Storage: ${_useHardwareEnclave ? 'Enabled' : 'Disabled'}", style: const TextStyle(color: LysenTheme.taupeAcc, fontSize: 12)),
                    const SizedBox(height: 4),
                    const Text("X.509 Certificate: Self-Signed Lysen CA", style: TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  Flexible(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(foregroundColor: LysenTheme.silverAcc),
                      child: const Text("Back"),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                const SizedBox(width: 8),
                Flexible(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep < 2) {
                        setState(() => _currentStep++);
                      } else {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Key Rotation Complete! New Ed25519 Keypair generated.")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LysenTheme.silverAcc,
                      foregroundColor: LysenTheme.pureBlack,
                    ),
                    child: Text(
                      _currentStep == 2 ? "Generate Keypair" : "Next",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioOptionTile extends StatelessWidget {
  final String title;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelect;

  const _RadioOptionTile({
    required this.title,
    required this.value,
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = value == selectedValue;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? LysenTheme.silverAcc.withValues(alpha: 0.12) : const Color(0xFF070505),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? LysenTheme.silverAcc : LysenTheme.borderGlass,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? LysenTheme.silverAcc : LysenTheme.textMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? LysenTheme.textPrimary : LysenTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
