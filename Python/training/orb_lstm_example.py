"""
ORB LSTM Integration Example
============================

This is a template showing how to train an LSTM model for ORB strategy enhancement.
The model predicts the probability of successful ORB breakout.

Future integration with ORB_Professional.mq5:
1. Train this model on historical data
2. Export weights to binary format
3. Load in MQL5 using file I/O
4. Use predictions to filter trades

Author: Claude
Date: 2024-11-15
"""

import numpy as np
import pandas as pd
from sklearn.preprocessing import RobustScaler
from sklearn.model_selection import TimeSeriesSplit
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
import joblib

# Configuration
SEQUENCE_LENGTH = 60  # Look back 60 bars
FEATURES = [
    'orb_range',      # ORB range size
    'orb_position',   # Price position within ORB (0-1)
    'atr',            # ATR value
    'volume',         # Volume
    'hour',           # Time of day
    'adx',            # Trend strength
    'rsi',            # Momentum
]

class ORBLSTMModel:
    def __init__(self, sequence_length=60, n_features=7):
        self.sequence_length = sequence_length
        self.n_features = n_features
        self.model = None
        self.scaler = RobustScaler()

    def create_model(self):
        """Create LSTM architecture"""
        model = keras.Sequential([
            # LSTM layers
            layers.LSTM(64, return_sequences=True, input_shape=(self.sequence_length, self.n_features)),
            layers.Dropout(0.2),
            layers.LSTM(32, return_sequences=False),
            layers.Dropout(0.2),

            # Dense layers
            layers.Dense(16, activation='relu'),
            layers.Dropout(0.1),
            layers.Dense(1, activation='sigmoid')  # Probability output (0-1)
        ])

        model.compile(
            optimizer=keras.optimizers.Adam(learning_rate=0.001),
            loss='binary_crossentropy',
            metrics=['accuracy', 'AUC']
        )

        self.model = model
        return model

    def prepare_data(self, df):
        """
        Prepare data for LSTM training

        Parameters:
        df: DataFrame with columns:
            - timestamp
            - open, high, low, close, volume
            - orb_high, orb_low (pre-calculated ORB levels)
            - breakout_success (target: 1 if TP hit, 0 if SL hit)
        """
        # Calculate features
        df['orb_range'] = df['orb_high'] - df['orb_low']
        df['orb_position'] = (df['close'] - df['orb_low']) / df['orb_range']

        # Normalize features
        feature_data = df[FEATURES].values
        scaled_features = self.scaler.fit_transform(feature_data)

        # Create sequences
        X, y = [], []
        for i in range(self.sequence_length, len(scaled_features)):
            X.append(scaled_features[i-self.sequence_length:i])
            y.append(df['breakout_success'].iloc[i])

        return np.array(X), np.array(y)

    def train(self, X_train, y_train, X_val, y_val, epochs=100):
        """Train the model with early stopping"""

        # Callbacks
        early_stop = keras.callbacks.EarlyStopping(
            monitor='val_loss',
            patience=15,
            restore_best_weights=True
        )

        reduce_lr = keras.callbacks.ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=5,
            min_lr=1e-6
        )

        # Train
        history = self.model.fit(
            X_train, y_train,
            validation_data=(X_val, y_val),
            epochs=epochs,
            batch_size=32,
            callbacks=[early_stop, reduce_lr],
            verbose=1
        )

        return history

    def export_for_mql5(self, filename='orb_lstm_weights.npz'):
        """Export model weights for MQL5 integration"""

        weights_dict = {}
        for i, layer in enumerate(self.model.layers):
            if len(layer.get_weights()) > 0:
                weights_dict[f'layer_{i}_weights'] = layer.get_weights()

        np.savez(filename, **weights_dict)

        # Also save scaler
        joblib.dump(self.scaler, 'orb_lstm_scaler.pkl')

        print(f"Model exported to {filename}")
        print(f"Scaler exported to orb_lstm_scaler.pkl")

    def predict_breakout_probability(self, sequence):
        """
        Predict probability of successful breakout

        Parameters:
        sequence: numpy array of shape (sequence_length, n_features)

        Returns:
        float: Probability (0-1) of breakout success
        """
        sequence_scaled = self.scaler.transform(sequence)
        sequence_scaled = sequence_scaled.reshape(1, self.sequence_length, self.n_features)

        probability = self.model.predict(sequence_scaled, verbose=0)[0][0]
        return probability


def example_usage():
    """Example of how to use the ORBLSTMModel"""

    # 1. Load your historical data
    # df = pd.read_csv('xauusd_orb_data.csv')
    # For this example, we'll create dummy data
    print("Creating dummy data for demonstration...")

    n_samples = 10000
    df = pd.DataFrame({
        'timestamp': pd.date_range('2023-01-01', periods=n_samples, freq='1H'),
        'open': np.random.randn(n_samples).cumsum() + 2000,
        'high': np.random.randn(n_samples).cumsum() + 2005,
        'low': np.random.randn(n_samples).cumsum() + 1995,
        'close': np.random.randn(n_samples).cumsum() + 2000,
        'volume': np.random.randint(100, 1000, n_samples),
        'orb_high': np.random.randn(n_samples).cumsum() + 2010,
        'orb_low': np.random.randn(n_samples).cumsum() + 1990,
        'orb_range': np.random.uniform(10, 50, n_samples),
        'orb_position': np.random.uniform(0, 1, n_samples),
        'atr': np.random.uniform(5, 20, n_samples),
        'adx': np.random.uniform(10, 40, n_samples),
        'rsi': np.random.uniform(30, 70, n_samples),
        'hour': (pd.date_range('2023-01-01', periods=n_samples, freq='1H').hour),
        'breakout_success': np.random.randint(0, 2, n_samples)  # 0 or 1
    })

    # 2. Initialize model
    print("\nInitializing LSTM model...")
    model = ORBLSTMModel(sequence_length=60, n_features=len(FEATURES))
    model.create_model()

    # 3. Prepare data
    print("Preparing training data...")
    X, y = model.prepare_data(df)

    # 4. Split data (time-based, NO shuffle!)
    split_idx = int(0.8 * len(X))
    X_train, X_val = X[:split_idx], X[split_idx:]
    y_train, y_val = y[:split_idx], y[split_idx:]

    print(f"Training samples: {len(X_train)}")
    print(f"Validation samples: {len(X_val)}")
    print(f"Input shape: {X_train.shape}")

    # 5. Train model
    print("\nTraining model...")
    print("NOTE: This is dummy data, so results won't be meaningful")
    print("Replace with real ORB backtest data for actual training\n")

    history = model.train(X_train, y_train, X_val, y_val, epochs=10)  # Short run for demo

    # 6. Evaluate
    val_loss, val_acc, val_auc = model.model.evaluate(X_val, y_val, verbose=0)
    print(f"\nValidation Accuracy: {val_acc:.4f}")
    print(f"Validation AUC: {val_auc:.4f}")

    # 7. Export for MQL5
    print("\nExporting model for MQL5...")
    model.export_for_mql5('orb_lstm_weights.npz')

    # 8. Example prediction
    print("\nExample prediction:")
    test_sequence = X_val[0]
    probability = model.predict_breakout_probability(test_sequence)
    print(f"Breakout success probability: {probability:.4f}")
    print(f"Actual result: {y_val[0]}")

    # 9. Trading rule example
    print("\n=== Trading Rule Example ===")
    print("In MQL5, you would:")
    print("1. Calculate current features (ORB range, ATR, etc.)")
    print("2. Load LSTM weights from file")
    print("3. Run forward propagation")
    print("4. Get probability prediction")
    print("5. Only trade if probability > threshold (e.g., 0.65)")
    print("\nExample: If probability = 0.75, take the breakout trade")
    print("         If probability = 0.45, skip the trade")


if __name__ == "__main__":
    print("=" * 60)
    print("ORB LSTM Model - Training Example")
    print("=" * 60)
    example_usage()
    print("\n" + "=" * 60)
    print("Next Steps:")
    print("1. Collect real ORB backtest data from MT5")
    print("2. Calculate features (ATR, ADX, RSI, etc.)")
    print("3. Label breakouts (1 = TP hit, 0 = SL hit)")
    print("4. Train model with real data")
    print("5. Export weights")
    print("6. Integrate with ORB_Professional.mq5")
    print("=" * 60)
