import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import { AppliedPromoCode } from '../types';

interface PromoCodeInputProps {
  appliedCode: AppliedPromoCode | null;
  onApply: (code: string) => Promise<void>;
  onRemove: () => Promise<void>;
  disabled?: boolean;
}

/**
 * Promo entry for the cart. Two states:
 *  - no code applied: text field + Apply, with an inline error under the field
 *  - code applied: a chip showing the code/description with a Remove action
 * Errors come from the server so the wording stays in one place.
 */
export const PromoCodeInput: React.FC<PromoCodeInputProps> = ({
  appliedCode,
  onApply,
  onRemove,
  disabled = false,
}) => {
  const [code, setCode] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const handleApply = async () => {
    if (!code.trim()) {
      setError('Please enter a promo code.');
      return;
    }
    setBusy(true);
    setError(null);
    try {
      await onApply(code);
      setCode('');
    } catch (e: any) {
      setError(e?.message || "That code couldn't be applied.");
    } finally {
      setBusy(false);
    }
  };

  const handleRemove = async () => {
    setBusy(true);
    setError(null);
    try {
      await onRemove();
    } catch (e: any) {
      setError(e?.message || "Couldn't remove the code.");
    } finally {
      setBusy(false);
    }
  };

  if (appliedCode) {
    return (
      <View style={styles.container}>
        <View style={styles.appliedRow} testID="promo-applied">
          <View style={styles.appliedTextBox}>
            <Text style={styles.appliedCode}>{appliedCode.code}</Text>
            <Text style={styles.appliedDescription}>{appliedCode.description} applied</Text>
          </View>
          <TouchableOpacity
            onPress={handleRemove}
            disabled={busy || disabled}
            accessibilityRole="button"
            accessibilityLabel={`Remove promo code ${appliedCode.code}`}
            testID="promo-remove"
          >
            {busy ? (
              <ActivityIndicator color="#FF3B30" />
            ) : (
              <Text style={styles.removeText}>Remove</Text>
            )}
          </TouchableOpacity>
        </View>
        {error ? <Text style={styles.error}>{error}</Text> : null}
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.inputRow}>
        <TextInput
          style={[styles.input, error ? styles.inputError : null]}
          value={code}
          onChangeText={text => {
            setCode(text);
            if (error) {
              setError(null);
            }
          }}
          placeholder="Promo code"
          autoCapitalize="characters"
          autoCorrect={false}
          returnKeyType="done"
          onSubmitEditing={handleApply}
          editable={!busy && !disabled}
          accessibilityLabel="Promo code"
          testID="promo-input"
        />
        <TouchableOpacity
          style={[styles.applyButton, (busy || disabled) && styles.applyDisabled]}
          onPress={handleApply}
          disabled={busy || disabled}
          accessibilityRole="button"
          testID="promo-apply"
        >
          {busy ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.applyText}>Apply</Text>
          )}
        </TouchableOpacity>
      </View>
      {error ? (
        <Text style={styles.error} accessibilityLiveRegion="polite" testID="promo-error">
          {error}
        </Text>
      ) : null}
    </View>
  );
};

const styles = StyleSheet.create({
  container: { marginBottom: 12 },
  inputRow: { flexDirection: 'row', alignItems: 'center' },
  input: {
    flex: 1,
    height: 44,
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    paddingHorizontal: 12,
    fontSize: 16,
    marginRight: 8,
    color: '#333',
  },
  inputError: { borderColor: '#FF3B30' },
  applyButton: {
    height: 44,
    paddingHorizontal: 16,
    borderRadius: 8,
    backgroundColor: '#007AFF',
    alignItems: 'center',
    justifyContent: 'center',
  },
  applyDisabled: { opacity: 0.5 },
  applyText: { color: '#fff', fontSize: 16, fontWeight: '600' },
  error: { color: '#FF3B30', fontSize: 13, marginTop: 6 },
  appliedRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#E8F8EE',
    borderRadius: 8,
    padding: 12,
  },
  appliedTextBox: { flex: 1 },
  appliedCode: { fontSize: 16, fontWeight: '700', color: '#1E7B3A' },
  appliedDescription: { fontSize: 13, color: '#1E7B3A', marginTop: 2 },
  removeText: { color: '#FF3B30', fontSize: 14, fontWeight: '600' },
});
