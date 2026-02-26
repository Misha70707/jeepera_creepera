import time
import numpy as np
import pandas as pd
import sys
import os

# Add current directory to path so we can import Python.training...
sys.path.append(os.getcwd())

from Python.training.orb_lstm_example import ORBLSTMDataPrep

def benchmark():
    # Setup dummy data
    N_ROWS = 100000
    N_FEATURES = 10
    SEQUENCE_LENGTH = 60

    print(f"Generating {N_ROWS} rows of dummy data with {N_FEATURES} features...")

    # Create random features
    # Use random float numbers
    scaled_features = np.random.rand(N_ROWS, N_FEATURES)

    # Create random target
    df = pd.DataFrame({
        'breakout_success': np.random.randint(0, 2, size=N_ROWS)
    })

    processor = ORBLSTMDataPrep(sequence_length=SEQUENCE_LENGTH)

    print("Starting benchmark of prepare_sequences...")
    start_time = time.time()

    X, y = processor.prepare_sequences(scaled_features, df)

    end_time = time.time()
    duration = end_time - start_time

    print(f"Execution time: {duration:.4f} seconds")
    print(f"Output X shape: {X.shape}")
    print(f"Output y shape: {y.shape}")

    # Basic validation
    assert len(X) == N_ROWS - SEQUENCE_LENGTH
    assert len(y) == N_ROWS - SEQUENCE_LENGTH
    assert X.shape[1] == SEQUENCE_LENGTH
    assert X.shape[2] == N_FEATURES

if __name__ == "__main__":
    benchmark()
