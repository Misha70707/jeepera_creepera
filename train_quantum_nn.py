#!/usr/bin/env python3
"""
Quantum Elite Neural Network Trainer
Trains neural network for trading signal prediction
Exports weights compatible with MQL5 EA
"""

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split, TimeSeriesSplit
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
import struct
import warnings
warnings.filterwarnings('ignore')

class QuantumNNTrainer:
    def __init__(self, input_size=10, hidden_size=20, output_size=3):
        """
        Initialize neural network architecture
        input_size: Number of input features
        hidden_size: Number of hidden neurons
        output_size: Number of output classes (sell=0, hold=1, buy=2)
        """
        self.input_size = input_size
        self.hidden_size = hidden_size
        self.output_size = output_size

        # Initialize weights with He initialization
        self.weights_input_hidden = np.random.randn(input_size, hidden_size) * np.sqrt(2.0 / input_size)
        self.weights_hidden_output = np.random.randn(hidden_size, output_size) * np.sqrt(2.0 / hidden_size)

        self.bias_hidden = np.zeros((1, hidden_size))
        self.bias_output = np.zeros((1, output_size))

        self.scaler = StandardScaler()
        self.training_history = {'loss': [], 'accuracy': []}

    def relu(self, x):
        """ReLU activation function"""
        return np.maximum(0, x)

    def relu_derivative(self, x):
        """Derivative of ReLU"""
        return (x > 0).astype(float)

    def softmax(self, x):
        """Softmax activation for output layer"""
        exp_x = np.exp(x - np.max(x, axis=1, keepdims=True))
        return exp_x / np.sum(exp_x, axis=1, keepdims=True)

    def forward(self, X):
        """Forward propagation"""
        # Input -> Hidden
        self.z1 = np.dot(X, self.weights_input_hidden) + self.bias_hidden
        self.a1 = self.relu(self.z1)

        # Hidden -> Output
        self.z2 = np.dot(self.a1, self.weights_hidden_output) + self.bias_output
        self.a2 = self.softmax(self.z2)

        return self.a2

    def backward(self, X, y, learning_rate=0.01):
        """Backpropagation"""
        m = X.shape[0]

        # Output layer gradients
        dz2 = self.a2 - y
        dw2 = np.dot(self.a1.T, dz2) / m
        db2 = np.sum(dz2, axis=0, keepdims=True) / m

        # Hidden layer gradients
        da1 = np.dot(dz2, self.weights_hidden_output.T)
        dz1 = da1 * self.relu_derivative(self.z1)
        dw1 = np.dot(X.T, dz1) / m
        db1 = np.sum(dz1, axis=0, keepdims=True) / m

        # Update weights
        self.weights_hidden_output -= learning_rate * dw2
        self.bias_output -= learning_rate * db2
        self.weights_input_hidden -= learning_rate * dw1
        self.bias_hidden -= learning_rate * db1

    def cross_entropy_loss(self, y_true, y_pred):
        """Calculate cross-entropy loss"""
        m = y_true.shape[0]
        log_likelihood = -np.log(y_pred[range(m), y_true.argmax(axis=1)])
        loss = np.sum(log_likelihood) / m
        return loss

    def train(self, X_train, y_train, X_val, y_val, epochs=100, learning_rate=0.01, batch_size=32):
        """Train the neural network"""
        print(f"\n{'='*60}")
        print("TRAINING QUANTUM NEURAL NETWORK")
        print(f"{'='*60}")
        print(f"Architecture: {self.input_size} -> {self.hidden_size} -> {self.output_size}")
        print(f"Training samples: {X_train.shape[0]}")
        print(f"Validation samples: {X_val.shape[0]}")
        print(f"Epochs: {epochs}, Learning rate: {learning_rate}, Batch size: {batch_size}")
        print(f"{'='*60}\n")

        best_val_accuracy = 0
        patience = 10
        patience_counter = 0

        for epoch in range(epochs):
            # Mini-batch training
            indices = np.random.permutation(X_train.shape[0])
            X_train_shuffled = X_train[indices]
            y_train_shuffled = y_train[indices]

            epoch_loss = 0
            num_batches = 0

            for i in range(0, X_train.shape[0], batch_size):
                X_batch = X_train_shuffled[i:i+batch_size]
                y_batch = y_train_shuffled[i:i+batch_size]

                # Forward + Backward
                y_pred = self.forward(X_batch)
                self.backward(X_batch, y_batch, learning_rate)

                epoch_loss += self.cross_entropy_loss(y_batch, y_pred)
                num_batches += 1

            avg_loss = epoch_loss / num_batches

            # Validation
            y_val_pred = self.forward(X_val)
            val_loss = self.cross_entropy_loss(y_val, y_val_pred)
            val_accuracy = accuracy_score(y_val.argmax(axis=1), y_val_pred.argmax(axis=1))

            self.training_history['loss'].append(avg_loss)
            self.training_history['accuracy'].append(val_accuracy)

            # Print progress
            if (epoch + 1) % 10 == 0:
                print(f"Epoch {epoch+1:3d}/{epochs} | "
                      f"Train Loss: {avg_loss:.4f} | "
                      f"Val Loss: {val_loss:.4f} | "
                      f"Val Accuracy: {val_accuracy:.4f}")

            # Early stopping
            if val_accuracy > best_val_accuracy:
                best_val_accuracy = val_accuracy
                patience_counter = 0
            else:
                patience_counter += 1
                if patience_counter >= patience:
                    print(f"\n⚠️  Early stopping at epoch {epoch+1}")
                    break

        print(f"\n✅ Training complete! Best validation accuracy: {best_val_accuracy:.4f}")

    def evaluate(self, X_test, y_test):
        """Evaluate model on test set"""
        print(f"\n{'='*60}")
        print("TEST SET EVALUATION")
        print(f"{'='*60}")

        y_pred = self.forward(X_test)
        y_pred_classes = y_pred.argmax(axis=1)
        y_true_classes = y_test.argmax(axis=1)

        accuracy = accuracy_score(y_true_classes, y_pred_classes)

        print(f"\nTest Accuracy: {accuracy:.4f}\n")
        print("Classification Report:")
        print(classification_report(y_true_classes, y_pred_classes,
                                   target_names=['SELL', 'HOLD', 'BUY']))

        # Confusion matrix
        cm = confusion_matrix(y_true_classes, y_pred_classes)
        print("Confusion Matrix:")
        print(cm)

        return accuracy

    def visualize_training(self):
        """Visualize training history"""
        fig, axes = plt.subplots(1, 2, figsize=(14, 5))

        # Loss plot
        axes[0].plot(self.training_history['loss'], label='Training Loss')
        axes[0].set_xlabel('Epoch')
        axes[0].set_ylabel('Loss')
        axes[0].set_title('Training Loss Over Time')
        axes[0].legend()
        axes[0].grid(True, alpha=0.3)

        # Accuracy plot
        axes[1].plot(self.training_history['accuracy'], label='Validation Accuracy', color='green')
        axes[1].set_xlabel('Epoch')
        axes[1].set_ylabel('Accuracy')
        axes[1].set_title('Validation Accuracy Over Time')
        axes[1].legend()
        axes[1].grid(True, alpha=0.3)

        plt.tight_layout()
        plt.savefig('quantum_nn_training.png', dpi=300, bbox_inches='tight')
        print(f"\n📊 Training visualization saved to: quantum_nn_training.png")
        plt.close()

    def export_weights_for_mql5(self, filename='nn_weights.bin'):
        """Export weights in binary format for MQL5"""
        print(f"\n{'='*60}")
        print("EXPORTING WEIGHTS FOR MQL5")
        print(f"{'='*60}")

        with open(filename, 'wb') as f:
            # Write architecture info
            f.write(struct.pack('iii', self.input_size, self.hidden_size, self.output_size))

            # Write weights_input_hidden (10x20)
            for i in range(self.input_size):
                for j in range(self.hidden_size):
                    f.write(struct.pack('d', self.weights_input_hidden[i, j]))

            # Write weights_hidden_output (20x3)
            for i in range(self.hidden_size):
                for j in range(self.output_size):
                    f.write(struct.pack('d', self.weights_hidden_output[i, j]))

            # Write bias_hidden (20)
            for i in range(self.hidden_size):
                f.write(struct.pack('d', self.bias_hidden[0, i]))

            # Write bias_output (3)
            for i in range(self.output_size):
                f.write(struct.pack('d', self.bias_output[0, i]))

        print(f"✅ Weights exported to: {filename}")
        print(f"File size: {os.path.getsize(filename)} bytes")
        print(f"\nCopy this file to MT5/MQL5/Files/ directory")

def generate_synthetic_data(n_samples=5000):
    """Generate synthetic trading data for training"""
    print("\n📊 Generating synthetic training data...")

    np.random.seed(42)

    # Generate features
    rsi = np.random.uniform(0, 100, n_samples)
    macd = np.random.uniform(-0.01, 0.01, n_samples)
    macd_signal = np.random.uniform(-0.01, 0.01, n_samples)
    stoch = np.random.uniform(0, 100, n_samples)
    atr = np.random.uniform(0.0001, 0.001, n_samples)

    # Price returns
    return_1bar = np.random.normal(0, 0.001, n_samples)
    return_5bar = np.random.normal(0, 0.002, n_samples)

    # Time features
    hour_sin = np.random.uniform(-1, 1, n_samples)
    hour_cos = np.random.uniform(-1, 1, n_samples)

    # Regime
    regime = np.random.choice([0, 1], n_samples)

    # Create feature matrix
    X = np.column_stack([
        (rsi - 50) / 50,                          # Normalized RSI
        np.tanh(macd * 1000),                     # Normalized MACD
        np.tanh((macd - macd_signal) * 1000),     # MACD difference
        (stoch - 50) / 50,                        # Normalized Stochastic
        np.tanh(atr * 10000),                     # Normalized ATR
        return_1bar * 100,                        # 1-bar return
        return_5bar * 100,                        # 5-bar return
        hour_sin,                                 # Hour (cyclical)
        hour_cos,
        regime * 2 - 1                           # Regime (-1 or 1)
    ])

    # Generate labels based on features (trading logic)
    labels = []
    for i in range(n_samples):
        # Buy signal: RSI oversold, positive MACD, strong upward momentum
        if rsi[i] < 30 and macd[i] > macd_signal[i] and return_1bar[i] > 0:
            labels.append(2)  # BUY
        # Sell signal: RSI overbought, negative MACD, downward momentum
        elif rsi[i] > 70 and macd[i] < macd_signal[i] and return_1bar[i] < 0:
            labels.append(0)  # SELL
        # Hold otherwise
        else:
            labels.append(1)  # HOLD

    y = np.array(labels)

    # Convert to one-hot encoding
    y_one_hot = np.zeros((n_samples, 3))
    y_one_hot[np.arange(n_samples), y] = 1

    print(f"✅ Generated {n_samples} samples")
    print(f"Class distribution: SELL={np.sum(y==0)}, HOLD={np.sum(y==1)}, BUY={np.sum(y==2)}")

    return X, y_one_hot

def main():
    print("╔════════════════════════════════════════════╗")
    print("║   QUANTUM ELITE NEURAL NETWORK TRAINER    ║")
    print("╚════════════════════════════════════════════╝")

    # Generate data
    X, y = generate_synthetic_data(n_samples=5000)

    # Split data (time-series aware)
    split_idx = int(0.7 * len(X))
    val_split_idx = int(0.85 * len(X))

    X_train = X[:split_idx]
    y_train = y[:split_idx]
    X_val = X[split_idx:val_split_idx]
    y_val = y[split_idx:val_split_idx]
    X_test = X[val_split_idx:]
    y_test = y[val_split_idx:]

    print(f"\nData split:")
    print(f"  Training:   {X_train.shape[0]} samples")
    print(f"  Validation: {X_val.shape[0]} samples")
    print(f"  Test:       {X_test.shape[0]} samples")

    # Initialize and train model
    nn = QuantumNNTrainer(input_size=10, hidden_size=20, output_size=3)
    nn.train(X_train, y_train, X_val, y_val,
            epochs=100, learning_rate=0.05, batch_size=64)

    # Evaluate
    nn.evaluate(X_test, y_test)

    # Visualize
    nn.visualize_training()

    # Export weights
    import os
    nn.export_weights_for_mql5('nn_weights.bin')

    print(f"\n{'='*60}")
    print("✅ TRAINING COMPLETE!")
    print(f"{'='*60}")
    print("\nNext steps:")
    print("1. Copy 'nn_weights.bin' to MT5/MQL5/Files/ directory")
    print("2. Load QUANTUM_ELITE_EA.mq5 in MetaTrader 5")
    print("3. Enable 'Use Neural Network' in EA settings")
    print("4. Start trading!")
    print(f"{'='*60}\n")

if __name__ == '__main__':
    main()
