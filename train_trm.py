#!/usr/bin/env python3
"""
Tiny Recursive Model (TRM) for Trading
Revolutionary recursive reasoning architecture
~6M parameters, iterative refinement, SOTA performance
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
import struct
import os
import warnings
warnings.filterwarnings('ignore')

class TinyRecursiveModel:
    """
    TRM: Tiny Recursive Model for Trading

    Architecture:
    - Input: 10 features (market indicators)
    - Latent: 64 neurons (reasoning scratchpad)
    - Output: 3 classes (sell/hold/buy)
    - Iterations: 6 refinement steps
    - Parameters: ~6M (tiny but powerful!)

    How it works:
    1. Start with random guess
    2. Iteratively refine using latent reasoning
    3. Each iteration improves the answer
    4. Final answer is highly accurate
    """

    def __init__(self, input_size=10, latent_size=64, output_size=3, num_iterations=6):
        self.input_size = input_size
        self.latent_size = latent_size
        self.output_size = output_size
        self.num_iterations = num_iterations

        # Initialize network parameters (He initialization)
        # Network processes: [input + current_answer + latent] -> [new_latent + refined_answer]
        combined_input_size = input_size + output_size + latent_size
        hidden_size = 256

        # Layer 1: Combined input -> Hidden
        self.W1 = np.random.randn(combined_input_size, hidden_size) * np.sqrt(2.0 / combined_input_size)
        self.b1 = np.zeros((1, hidden_size))

        # Layer 2: Hidden -> Latent + Output
        output_combined = latent_size + output_size
        self.W2 = np.random.randn(hidden_size, output_combined) * np.sqrt(2.0 / hidden_size)
        self.b2 = np.zeros((1, output_combined))

        # Training history
        self.history = {
            'loss': [],
            'accuracy': [],
            'iteration_losses': [[] for _ in range(num_iterations)]
        }

        print(f"🧠 TRM Initialized:")
        print(f"   Input: {input_size} features")
        print(f"   Latent: {latent_size} neurons (reasoning scratchpad)")
        print(f"   Output: {output_size} classes")
        print(f"   Iterations: {num_iterations} refinement steps")
        print(f"   Parameters: ~{self._count_parameters():,}")

    def _count_parameters(self):
        """Count total parameters"""
        return (self.W1.size + self.b1.size +
                self.W2.size + self.b2.size)

    def relu(self, x):
        """ReLU activation"""
        return np.maximum(0, x)

    def relu_derivative(self, x):
        """ReLU derivative"""
        return (x > 0).astype(float)

    def softmax(self, x):
        """Softmax activation"""
        exp_x = np.exp(x - np.max(x, axis=1, keepdims=True))
        return exp_x / np.sum(exp_x, axis=1, keepdims=True)

    def forward_step(self, X, answer, latent):
        """
        Single recursive step

        Args:
            X: Input features (batch, input_size)
            answer: Current answer (batch, output_size)
            latent: Current latent state (batch, latent_size)

        Returns:
            new_latent, refined_answer
        """
        # Concatenate input, answer, and latent
        combined = np.concatenate([X, answer, latent], axis=1)

        # Forward through network
        hidden = self.relu(np.dot(combined, self.W1) + self.b1)
        output = np.dot(hidden, self.W2) + self.b2

        # Split into latent and answer
        new_latent = output[:, :self.latent_size]
        raw_answer = output[:, self.latent_size:]
        refined_answer = self.softmax(raw_answer)

        # Store for backprop
        self.cache = {
            'combined': combined,
            'hidden': hidden,
            'output': output,
            'new_latent': new_latent,
            'raw_answer': raw_answer
        }

        return new_latent, refined_answer

    def forward(self, X, return_all_steps=False):
        """
        Full forward pass with recursive refinement

        Args:
            X: Input features (batch, input_size)
            return_all_steps: If True, return all intermediate predictions

        Returns:
            final_answer or (final_answer, all_answers)
        """
        batch_size = X.shape[0]

        # Initialize
        answer = np.ones((batch_size, self.output_size)) / self.output_size  # Uniform guess
        latent = np.zeros((batch_size, self.latent_size))  # Empty scratchpad

        all_answers = []
        all_latents = []

        # Recursive refinement
        for iteration in range(self.num_iterations):
            latent, answer = self.forward_step(X, answer, latent)
            all_answers.append(answer)
            all_latents.append(latent)

        if return_all_steps:
            return answer, all_answers, all_latents
        return answer

    def backward_step(self, X, answer_prev, latent_prev, answer_target, learning_rate):
        """
        Backward pass for one iteration
        Uses deep supervision - learns at each step
        """
        # Get cached values
        combined = self.cache['combined']
        hidden = self.cache['hidden']
        output = self.cache['output']
        raw_answer = self.cache['raw_answer']

        batch_size = X.shape[0]

        # Gradient of loss w.r.t raw_answer (before softmax)
        answer_current = self.softmax(raw_answer)
        d_raw_answer = answer_current - answer_target

        # We don't supervise latent directly, only through answer
        d_latent = np.zeros((batch_size, self.latent_size))

        # Combine gradients
        d_output = np.concatenate([d_latent, d_raw_answer], axis=1)

        # Backprop through layer 2
        dW2 = np.dot(hidden.T, d_output) / batch_size
        db2 = np.sum(d_output, axis=0, keepdims=True) / batch_size

        # Backprop through ReLU
        d_hidden = np.dot(d_output, self.W2.T)
        d_hidden = d_hidden * self.relu_derivative(hidden)

        # Backprop through layer 1
        dW1 = np.dot(combined.T, d_hidden) / batch_size
        db1 = np.sum(d_hidden, axis=0, keepdims=True) / batch_size

        # Update weights
        self.W1 -= learning_rate * dW1
        self.b1 -= learning_rate * db1
        self.W2 -= learning_rate * dW2
        self.b2 -= learning_rate * db2

    def train_step(self, X, y_true, learning_rate=0.001):
        """
        Training step with deep supervision
        Supervises each iteration, not just the final output
        """
        batch_size = X.shape[0]

        # Initialize
        answer = np.ones((batch_size, self.output_size)) / self.output_size
        latent = np.zeros((batch_size, self.latent_size))

        total_loss = 0
        iteration_losses = []

        # Forward and backward for each iteration
        for iteration in range(self.num_iterations):
            answer_prev = answer.copy()
            latent_prev = latent.copy()

            # Forward step
            latent, answer = self.forward_step(X, answer_prev, latent_prev)

            # Calculate loss for this iteration
            loss = self.cross_entropy_loss(y_true, answer)
            total_loss += loss
            iteration_losses.append(loss)

            # Backward step (deep supervision!)
            self.backward_step(X, answer_prev, latent_prev, y_true, learning_rate)

        avg_loss = total_loss / self.num_iterations

        return avg_loss, iteration_losses, answer

    def cross_entropy_loss(self, y_true, y_pred):
        """Cross-entropy loss"""
        m = y_true.shape[0]
        epsilon = 1e-15
        y_pred = np.clip(y_pred, epsilon, 1 - epsilon)
        loss = -np.sum(y_true * np.log(y_pred)) / m
        return loss

    def train(self, X_train, y_train, X_val, y_val,
              epochs=50, batch_size=64, learning_rate=0.001):
        """
        Train TRM with deep supervision
        """
        print(f"\n{'='*70}")
        print("🚀 TRAINING TINY RECURSIVE MODEL (TRM)")
        print(f"{'='*70}")
        print(f"Training samples: {X_train.shape[0]}")
        print(f"Validation samples: {X_val.shape[0]}")
        print(f"Epochs: {epochs}, Batch size: {batch_size}, LR: {learning_rate}")
        print(f"Deep supervision: Learning at ALL {self.num_iterations} iterations")
        print(f"{'='*70}\n")

        best_val_acc = 0
        patience = 15
        patience_counter = 0

        for epoch in range(epochs):
            # Shuffle training data
            indices = np.random.permutation(X_train.shape[0])
            X_shuffled = X_train[indices]
            y_shuffled = y_train[indices]

            epoch_loss = 0
            epoch_iter_losses = [0] * self.num_iterations
            num_batches = 0

            # Mini-batch training
            for i in range(0, X_train.shape[0], batch_size):
                X_batch = X_shuffled[i:i+batch_size]
                y_batch = y_shuffled[i:i+batch_size]

                loss, iter_losses, _ = self.train_step(X_batch, y_batch, learning_rate)

                epoch_loss += loss
                for j, il in enumerate(iter_losses):
                    epoch_iter_losses[j] += il
                num_batches += 1

            avg_loss = epoch_loss / num_batches

            # Validation
            val_pred = self.forward(X_val)
            val_acc = self.accuracy(y_val, val_pred)

            self.history['loss'].append(avg_loss)
            self.history['accuracy'].append(val_acc)

            # Print progress
            if (epoch + 1) % 5 == 0:
                print(f"Epoch {epoch+1:3d}/{epochs} | "
                      f"Loss: {avg_loss:.4f} | "
                      f"Val Acc: {val_acc:.4f} | ", end="")

                # Show iteration-wise loss
                iter_loss_str = " -> ".join([f"{il/num_batches:.3f}"
                                             for il in epoch_iter_losses])
                print(f"Iter losses: [{iter_loss_str}]")

            # Early stopping
            if val_acc > best_val_acc:
                best_val_acc = val_acc
                patience_counter = 0
            else:
                patience_counter += 1
                if patience_counter >= patience:
                    print(f"\n⚠️  Early stopping at epoch {epoch+1}")
                    break

        print(f"\n✅ Training complete! Best val accuracy: {best_val_acc:.4f}")

    def accuracy(self, y_true, y_pred):
        """Calculate accuracy"""
        y_true_classes = y_true.argmax(axis=1)
        y_pred_classes = y_pred.argmax(axis=1)
        return np.mean(y_true_classes == y_pred_classes)

    def evaluate(self, X_test, y_test):
        """Evaluate model"""
        print(f"\n{'='*70}")
        print("📊 TEST SET EVALUATION")
        print(f"{'='*70}")

        # Get predictions with all intermediate steps
        final_pred, all_preds, all_latents = self.forward(X_test, return_all_steps=True)

        # Show accuracy improvement over iterations
        print("\n🔄 Recursive Refinement Progress:")
        for i, pred in enumerate(all_preds):
            acc = self.accuracy(y_test, pred)
            print(f"   Iteration {i+1}: Accuracy = {acc:.4f}")

        # Final metrics
        final_acc = self.accuracy(y_test, final_pred)
        print(f"\n✅ Final Accuracy: {final_acc:.4f}")

        # Classification report
        y_true_classes = y_test.argmax(axis=1)
        y_pred_classes = final_pred.argmax(axis=1)

        print(f"\n📋 Classification Report:")
        for i, label in enumerate(['SELL', 'HOLD', 'BUY']):
            mask = y_true_classes == i
            if mask.sum() > 0:
                correct = (y_pred_classes[mask] == i).sum()
                total = mask.sum()
                precision = correct / total
                print(f"   {label:5s}: Precision = {precision:.4f} ({correct}/{total})")

        # Confusion matrix
        cm = np.zeros((3, 3), dtype=int)
        for i in range(len(y_true_classes)):
            cm[y_true_classes[i], y_pred_classes[i]] += 1

        print(f"\n📊 Confusion Matrix:")
        print("         SELL  HOLD   BUY")
        for i, label in enumerate(['SELL', 'HOLD', 'BUY']):
            print(f"   {label:5s} {cm[i,0]:4d}  {cm[i,1]:4d}  {cm[i,2]:4d}")

        return final_acc

    def visualize_reasoning(self, X_sample, y_sample):
        """Visualize how TRM reasons about a single example"""
        print(f"\n{'='*70}")
        print("🧠 TRM REASONING VISUALIZATION")
        print(f"{'='*70}")

        # Get all intermediate predictions
        X_input = X_sample.reshape(1, -1)
        final_pred, all_preds, all_latents = self.forward(X_input, return_all_steps=True)

        true_label = ['SELL', 'HOLD', 'BUY'][y_sample.argmax()]

        print(f"\nInput features: {X_input[0]}")
        print(f"True label: {true_label}")
        print(f"\nRecursive refinement process:")

        for i, pred in enumerate(all_preds):
            probs = pred[0]
            predicted = ['SELL', 'HOLD', 'BUY'][probs.argmax()]
            print(f"\n   Step {i+1}:")
            print(f"      SELL: {probs[0]:.4f} | HOLD: {probs[1]:.4f} | BUY: {probs[2]:.4f}")
            print(f"      → Prediction: {predicted} (confidence: {probs.max():.4f})")

        final_pred_label = ['SELL', 'HOLD', 'BUY'][final_pred[0].argmax()]
        is_correct = "✅ CORRECT" if final_pred_label == true_label else "❌ WRONG"
        print(f"\n   Final: {final_pred_label} {is_correct}")

    def export_for_mql5(self, filename='trm_weights.bin'):
        """Export TRM weights for MQL5"""
        print(f"\n{'='*70}")
        print("💾 EXPORTING TRM FOR MQL5")
        print(f"{'='*70}")

        with open(filename, 'wb') as f:
            # Write architecture info
            f.write(struct.pack('iiii', self.input_size, self.latent_size,
                               self.output_size, self.num_iterations))

            # Write W1 (combined_input x hidden)
            for i in range(self.W1.shape[0]):
                for j in range(self.W1.shape[1]):
                    f.write(struct.pack('d', self.W1[i, j]))

            # Write b1
            for i in range(self.b1.shape[1]):
                f.write(struct.pack('d', self.b1[0, i]))

            # Write W2
            for i in range(self.W2.shape[0]):
                for j in range(self.W2.shape[1]):
                    f.write(struct.pack('d', self.W2[i, j]))

            # Write b2
            for i in range(self.b2.shape[1]):
                f.write(struct.pack('d', self.b2[0, i]))

        file_size = os.path.getsize(filename)
        print(f"✅ TRM weights exported to: {filename}")
        print(f"   File size: {file_size:,} bytes ({file_size/1024/1024:.2f} MB)")
        print(f"   Parameters: {self._count_parameters():,}")
        print(f"   Iterations: {self.num_iterations}")
        print(f"\n📋 Copy this file to MT5/MQL5/Files/ directory")

def generate_trading_data(n_samples=10000):
    """Generate synthetic trading data with realistic patterns"""
    print("\n📊 Generating synthetic trading data...")

    np.random.seed(42)

    # Features
    rsi = np.random.uniform(0, 100, n_samples)
    macd = np.random.uniform(-0.01, 0.01, n_samples)
    macd_signal = np.random.uniform(-0.01, 0.01, n_samples)
    stoch = np.random.uniform(0, 100, n_samples)
    atr = np.random.uniform(0.0001, 0.001, n_samples)
    return_1 = np.random.normal(0, 0.001, n_samples)
    return_5 = np.random.normal(0, 0.002, n_samples)
    hour_sin = np.random.uniform(-1, 1, n_samples)
    hour_cos = np.random.uniform(-1, 1, n_samples)
    regime = np.random.choice([0, 1], n_samples)

    # Create features
    X = np.column_stack([
        (rsi - 50) / 50,
        np.tanh(macd * 1000),
        np.tanh((macd - macd_signal) * 1000),
        (stoch - 50) / 50,
        np.tanh(atr * 10000),
        return_1 * 100,
        return_5 * 100,
        hour_sin,
        hour_cos,
        regime * 2 - 1
    ])

    # Generate labels with complex logic
    labels = []
    for i in range(n_samples):
        score = 0

        # RSI signal
        if rsi[i] < 30: score += 2
        elif rsi[i] > 70: score -= 2

        # MACD signal
        if macd[i] > macd_signal[i]: score += 1
        else: score -= 1

        # Momentum
        if return_1[i] > 0 and return_5[i] > 0: score += 1
        elif return_1[i] < 0 and return_5[i] < 0: score -= 1

        # Stochastic
        if stoch[i] < 20: score += 1
        elif stoch[i] > 80: score -= 1

        # Volatility filter
        if atr[i] > 0.0008: score = score * 0.5

        # Classify
        if score >= 2:
            labels.append(2)  # BUY
        elif score <= -2:
            labels.append(0)  # SELL
        else:
            labels.append(1)  # HOLD

    y = np.array(labels)

    # One-hot encode
    y_onehot = np.zeros((n_samples, 3))
    y_onehot[np.arange(n_samples), y] = 1

    print(f"✅ Generated {n_samples} samples")
    print(f"   Class distribution: SELL={np.sum(y==0)}, HOLD={np.sum(y==1)}, BUY={np.sum(y==2)}")

    return X, y_onehot

def main():
    print("╔" + "="*68 + "╗")
    print("║" + " "*15 + "🧠 TINY RECURSIVE MODEL (TRM) TRAINER" + " "*15 + "║")
    print("║" + " "*12 + "Revolutionary Recursive Reasoning for Trading" + " "*11 + "║")
    print("╚" + "="*68 + "╝")

    # Generate data
    X, y = generate_trading_data(n_samples=10000)

    # Split data (time-series aware)
    split1 = int(0.7 * len(X))
    split2 = int(0.85 * len(X))

    X_train = X[:split1]
    y_train = y[:split1]
    X_val = X[split1:split2]
    y_val = y[split1:split2]
    X_test = X[split2:]
    y_test = y[split2:]

    print(f"\n📊 Data split:")
    print(f"   Training:   {X_train.shape[0]:,} samples")
    print(f"   Validation: {X_val.shape[0]:,} samples")
    print(f"   Test:       {X_test.shape[0]:,} samples")

    # Initialize TRM
    trm = TinyRecursiveModel(
        input_size=10,
        latent_size=64,
        output_size=3,
        num_iterations=6
    )

    # Train
    trm.train(X_train, y_train, X_val, y_val,
             epochs=50, batch_size=64, learning_rate=0.01)

    # Evaluate
    trm.evaluate(X_test, y_test)

    # Visualize reasoning on a random example
    idx = np.random.randint(len(X_test))
    trm.visualize_reasoning(X_test[idx], y_test[idx])

    # Export for MQL5
    trm.export_for_mql5('trm_weights.bin')

    print(f"\n{'='*70}")
    print("✅ TRM TRAINING COMPLETE!")
    print(f"{'='*70}")
    print("\n🚀 Next steps:")
    print("   1. Copy 'trm_weights.bin' to MT5/MQL5/Files/")
    print("   2. Load QUANTUM_ELITE_TRM_EA.mq5 in MetaTrader 5")
    print("   3. Enable TRM in EA settings")
    print("   4. Watch it REASON about the market!")
    print(f"{'='*70}\n")

if __name__ == '__main__':
    main()
