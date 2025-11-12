#!/usr/bin/env python3
"""
Real ML Trading Model Trainer
Trains actual machine learning models on collected trading data
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, TimeSeriesSplit, cross_val_score
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score, f1_score
import joblib
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')

class TradingMLTrainer:
    def __init__(self, data_file='training_data.csv'):
        self.data_file = data_file
        self.model = None
        self.scaler = None
        self.feature_names = None
        self.feature_importance = None

    def load_and_prepare_data(self):
        """Load CSV data and prepare for training"""
        print("Loading data from:", self.data_file)

        # Load data
        df = pd.read_csv(self.data_file)
        print(f"Loaded {len(df)} data points")

        # Remove rows without labels (recent data that hasn't matured yet)
        df = df[df['optimal_action'].notna()]
        df = df[df['next_10bar_return'].notna()]

        print(f"After removing unlabeled data: {len(df)} points")

        if len(df) < 100:
            raise ValueError("Insufficient labeled data. Need at least 100 samples. Run DataCollector EA longer.")

        # Feature engineering
        df['bb_position'] = (df['close_norm'] - df['bb_lower']) / (df['bb_upper'] - df['bb_lower'] + 0.0001)
        df['rsi_normalized'] = df['rsi'] / 100.0
        df['macd_diff'] = df['macd_main'] - df['macd_signal']
        df['stoch_avg'] = (df['stoch_k'] + df['stoch_d']) / 2.0
        df['price_range'] = df['high_norm'] - df['low_norm']
        df['body_size'] = abs(df['close_norm'] - df['open_norm'])

        # Time-based features (cyclical encoding)
        df['hour_sin'] = np.sin(2 * np.pi * df['hour'] / 24)
        df['hour_cos'] = np.cos(2 * np.pi * df['hour'] / 24)
        df['dow_sin'] = np.sin(2 * np.pi * df['day_of_week'] / 7)
        df['dow_cos'] = np.cos(2 * np.pi * df['day_of_week'] / 7)

        # Select features
        feature_columns = [
            'close_norm', 'high_norm', 'low_norm', 'open_norm', 'volume_norm',
            'atr', 'rsi_normalized', 'macd_main', 'macd_signal', 'macd_diff',
            'bb_position', 'stoch_k', 'stoch_d', 'stoch_avg',
            'adx', 'cci',
            'momentum', 'velocity', 'acceleration',
            'support_distance', 'resistance_distance',
            'hour_sin', 'hour_cos', 'dow_sin', 'dow_cos',
            'price_range', 'body_size'
        ]

        # Remove any features with NaN
        feature_columns = [col for col in feature_columns if col in df.columns]

        X = df[feature_columns].copy()

        # Target: optimal_action (1=buy, -1=sell, 0=hold)
        # Convert to classification: 0=sell, 1=hold, 2=buy
        y = df['optimal_action'].copy()
        y = y.map({-1: 0, 0: 1, 1: 2})

        # Remove any remaining NaN
        mask = ~(X.isna().any(axis=1) | y.isna())
        X = X[mask]
        y = y[mask]

        print(f"Final dataset: {len(X)} samples with {len(feature_columns)} features")
        print(f"Class distribution:\n{y.value_counts()}")

        self.feature_names = feature_columns

        return X, y

    def train_model(self, X, y, model_type='random_forest'):
        """Train the ML model with proper validation"""
        print(f"\n{'='*60}")
        print(f"Training {model_type} model...")
        print(f"{'='*60}")

        # Time series split (important for financial data!)
        tscv = TimeSeriesSplit(n_splits=5)

        # Standardize features
        self.scaler = StandardScaler()
        X_scaled = self.scaler.fit_transform(X)

        # Choose model
        if model_type == 'random_forest':
            self.model = RandomForestClassifier(
                n_estimators=200,
                max_depth=15,
                min_samples_split=20,
                min_samples_leaf=10,
                max_features='sqrt',
                class_weight='balanced',  # Handle imbalanced classes
                random_state=42,
                n_jobs=-1
            )
        elif model_type == 'gradient_boosting':
            self.model = GradientBoostingClassifier(
                n_estimators=100,
                max_depth=10,
                min_samples_split=20,
                min_samples_leaf=10,
                learning_rate=0.1,
                random_state=42
            )
        else:
            raise ValueError(f"Unknown model type: {model_type}")

        # Cross-validation
        print("\nPerforming time-series cross-validation...")
        cv_scores = cross_val_score(self.model, X_scaled, y, cv=tscv, scoring='f1_weighted')
        print(f"CV Scores: {cv_scores}")
        print(f"Mean CV Score: {cv_scores.mean():.4f} (+/- {cv_scores.std() * 2:.4f})")

        # Train-test split (time-based!)
        split_idx = int(len(X_scaled) * 0.8)
        X_train, X_test = X_scaled[:split_idx], X_scaled[split_idx:]
        y_train, y_test = y[:split_idx], y[split_idx:]

        print(f"\nTrain set: {len(X_train)} samples")
        print(f"Test set: {len(X_test)} samples")

        # Train model
        print("\nTraining final model...")
        self.model.fit(X_train, y_train)

        # Evaluate
        print("\n" + "="*60)
        print("TRAINING SET PERFORMANCE")
        print("="*60)
        y_train_pred = self.model.predict(X_train)
        print(classification_report(y_train, y_train_pred,
                                   target_names=['SELL', 'HOLD', 'BUY']))

        print("\n" + "="*60)
        print("TEST SET PERFORMANCE (Out-of-sample)")
        print("="*60)
        y_test_pred = self.model.predict(X_test)
        print(classification_report(y_test, y_test_pred,
                                   target_names=['SELL', 'HOLD', 'BUY']))

        # Confusion matrix
        cm = confusion_matrix(y_test, y_test_pred)
        print("\nConfusion Matrix:")
        print(cm)

        # Feature importance
        if hasattr(self.model, 'feature_importances_'):
            self.feature_importance = pd.DataFrame({
                'feature': self.feature_names,
                'importance': self.model.feature_importances_
            }).sort_values('importance', ascending=False)

            print("\nTop 10 Most Important Features:")
            print(self.feature_importance.head(10))

        # Calculate accuracy by class
        print("\nAccuracy by Action:")
        for i, action in enumerate(['SELL', 'HOLD', 'BUY']):
            mask = y_test == i
            if mask.sum() > 0:
                acc = accuracy_score(y_test[mask], y_test_pred[mask])
                print(f"  {action}: {acc:.2%}")

        return X_test, y_test, y_test_pred

    def visualize_results(self, y_test, y_test_pred):
        """Create visualization plots"""
        print("\nGenerating visualizations...")

        fig, axes = plt.subplots(2, 2, figsize=(15, 12))

        # 1. Confusion Matrix
        cm = confusion_matrix(y_test, y_test_pred)
        sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
                   xticklabels=['SELL', 'HOLD', 'BUY'],
                   yticklabels=['SELL', 'HOLD', 'BUY'],
                   ax=axes[0, 0])
        axes[0, 0].set_title('Confusion Matrix')
        axes[0, 0].set_ylabel('True Label')
        axes[0, 0].set_xlabel('Predicted Label')

        # 2. Feature Importance
        if self.feature_importance is not None:
            top_features = self.feature_importance.head(15)
            axes[0, 1].barh(range(len(top_features)), top_features['importance'])
            axes[0, 1].set_yticks(range(len(top_features)))
            axes[0, 1].set_yticklabels(top_features['feature'])
            axes[0, 1].set_xlabel('Importance')
            axes[0, 1].set_title('Top 15 Feature Importances')
            axes[0, 1].invert_yaxis()

        # 3. Class Distribution
        class_counts = pd.Series(y_test).value_counts().sort_index()
        axes[1, 0].bar(['SELL', 'HOLD', 'BUY'], class_counts.values)
        axes[1, 0].set_title('Test Set Class Distribution')
        axes[1, 0].set_ylabel('Count')

        # 4. Prediction Confidence (if available)
        if hasattr(self.model, 'predict_proba'):
            probas = self.model.predict_proba(self.scaler.transform(
                pd.DataFrame(columns=self.feature_names, data=np.zeros((1, len(self.feature_names))))
            ))
            # Show confidence distribution
            axes[1, 1].text(0.5, 0.5, 'Model Trained Successfully!\nCheck exported files for details.',
                          ha='center', va='center', fontsize=14)
            axes[1, 1].axis('off')

        plt.tight_layout()
        plt.savefig('model_performance.png', dpi=300, bbox_inches='tight')
        print("Saved visualization to: model_performance.png")
        plt.close()

    def save_model(self, filename='trading_model.pkl'):
        """Save trained model and scaler"""
        if self.model is None or self.scaler is None:
            raise ValueError("Model not trained yet!")

        model_data = {
            'model': self.model,
            'scaler': self.scaler,
            'feature_names': self.feature_names,
            'feature_importance': self.feature_importance,
            'trained_date': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }

        joblib.dump(model_data, filename)
        print(f"\nModel saved to: {filename}")

        # Also export feature importance to CSV
        if self.feature_importance is not None:
            self.feature_importance.to_csv('feature_importance.csv', index=False)
            print("Feature importance saved to: feature_importance.csv")

    def export_for_mql5(self, filename='model_weights.txt'):
        """Export model in a format that can be loaded by MQL5"""
        if self.model is None:
            raise ValueError("Model not trained yet!")

        with open(filename, 'w') as f:
            f.write("# Trading Model Weights for MQL5\n")
            f.write(f"# Generated: {datetime.now()}\n")
            f.write(f"# Model Type: {type(self.model).__name__}\n\n")

            # Export feature names
            f.write("FEATURES\n")
            for feat in self.feature_names:
                f.write(f"{feat}\n")
            f.write("\n")

            # Export scaler parameters
            f.write("SCALER_MEAN\n")
            for mean in self.scaler.mean_:
                f.write(f"{mean:.10f}\n")
            f.write("\n")

            f.write("SCALER_SCALE\n")
            for scale in self.scaler.scale_:
                f.write(f"{scale:.10f}\n")
            f.write("\n")

            # For Random Forest, we can't export all trees easily
            # Instead, export feature importances and a simple decision rule
            if hasattr(self.model, 'feature_importances_'):
                f.write("FEATURE_IMPORTANCE\n")
                for imp in self.model.feature_importances_:
                    f.write(f"{imp:.10f}\n")

        print(f"Model weights exported to: {filename}")
        print("\nNote: For production use, consider using ONNX format")
        print("or implementing a simple rule-based system based on feature importances.")

def main():
    print("="*60)
    print("REAL ML TRADING MODEL TRAINER")
    print("="*60)
    print()

    trainer = TradingMLTrainer('training_data.csv')

    try:
        # Load data
        X, y = trainer.load_and_prepare_data()

        if len(X) < 100:
            print("\n⚠️  WARNING: Not enough data!")
            print("Run the DataCollector EA for at least 100 bars to collect training data.")
            return

        # Train model
        X_test, y_test, y_test_pred = trainer.train_model(X, y, model_type='random_forest')

        # Visualize
        trainer.visualize_results(y_test, y_test_pred)

        # Save model
        trainer.save_model('trading_model.pkl')
        trainer.export_for_mql5('model_weights.txt')

        print("\n" + "="*60)
        print("✅ TRAINING COMPLETE!")
        print("="*60)
        print("\nNext steps:")
        print("1. Review model_performance.png for model quality")
        print("2. Check feature_importance.csv for key features")
        print("3. If satisfied, use the model with the Trading EA")
        print("4. Always backtest before live trading!")
        print("="*60)

    except FileNotFoundError:
        print("\n❌ ERROR: training_data.csv not found!")
        print("\nPlease run the DataCollector EA first:")
        print("1. Copy DataCollector.mq5 to MT5")
        print("2. Run it on a chart (demo account recommended)")
        print("3. Let it collect data for at least 100 bars")
        print("4. The training_data.csv will appear in MT5/MQL5/Files/")
        print("5. Copy it to this directory and run this script again")
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()
