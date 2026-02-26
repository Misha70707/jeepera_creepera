import numpy as np
import pandas as pd

class ORBLSTMDataPrep:
    def __init__(self, sequence_length=60):
        self.sequence_length = sequence_length

    def prepare_sequences(self, scaled_features, df):
        """
        Optimized implementation of sequence creation using vectorized operations.
        """
        # Calculate number of samples
        num_samples = len(scaled_features) - self.sequence_length

        if num_samples <= 0:
            return np.empty((0, self.sequence_length, scaled_features.shape[1])), np.array([])

        num_features = scaled_features.shape[1]

        # Pre-allocate X array
        X = np.empty((num_samples, self.sequence_length, num_features))

        # Vectorized filling of X
        # Instead of iterating over samples (slow), iterate over sequence length (fast)
        for i in range(self.sequence_length):
            X[:, i, :] = scaled_features[i : i + num_samples]

        # Vectorized creation of y
        # We take the values starting from sequence_length to align with the targets
        y = df['breakout_success'].values[self.sequence_length:]

        return X, y
