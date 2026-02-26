import numpy as np
import pandas as pd
import sys
import os

sys.path.append(os.getcwd())
from Python.training.orb_lstm_example import ORBLSTMDataPrep

def old_implementation(self, scaled_features, df):
    X, y = [], []
    for i in range(self.sequence_length, len(scaled_features)):
        X.append(scaled_features[i-self.sequence_length:i])
        y.append(df['breakout_success'].iloc[i])
    return np.array(X), np.array(y)

def test_correctness():
    print("Verifying correctness...")
    N_ROWS = 1000
    N_FEATURES = 5
    SEQUENCE_LENGTH = 10

    # Create deterministic data
    np.random.seed(42)
    scaled_features = np.random.rand(N_ROWS, N_FEATURES)
    df = pd.DataFrame({'breakout_success': np.random.randint(0, 2, size=N_ROWS)})

    processor = ORBLSTMDataPrep(sequence_length=SEQUENCE_LENGTH)

    # Run optimized
    X_new, y_new = processor.prepare_sequences(scaled_features, df)

    # Run old logic (mimicked)
    X_old, y_old = old_implementation(processor, scaled_features, df)

    # Compare
    np.testing.assert_allclose(X_new, X_old, err_msg="X arrays differ")
    np.testing.assert_array_equal(y_new, y_old, err_msg="y arrays differ")

    print("Correctness verified: Optimized implementation matches original logic.")

if __name__ == "__main__":
    test_correctness()
