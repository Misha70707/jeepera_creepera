#!/usr/bin/env python3
"""
VECTORUM EA Backtesting Framework
Professional-grade backtester with detailed metrics and analysis
"""

import numpy as np
import pandas as pd
from datetime import datetime, timedelta
import json
from dataclasses import dataclass, field
from typing import List, Tuple, Optional
import statistics

@dataclass
class Trade:
    """Represents a single trade"""
    entry_time: int
    entry_price: float
    exit_time: int
    exit_price: float
    position_type: str  # 'BUY' or 'SELL'
    volume: float
    stop_loss: float
    take_profit: float
    exit_reason: str  # 'TP', 'SL', 'Signal'
    profit_loss: float = 0.0
    profit_pips: float = 0.0
    return_percent: float = 0.0

    def __post_init__(self):
        """Calculate P&L after initialization"""
        if self.position_type == 'BUY':
            self.profit_loss = (self.exit_price - self.entry_price) * self.volume * 100000
            self.profit_pips = (self.exit_price - self.entry_price) / 0.0001
        else:  # SELL
            self.profit_loss = (self.entry_price - self.exit_price) * self.volume * 100000
            self.profit_pips = (self.entry_price - self.exit_price) / 0.0001

        self.return_percent = (self.profit_loss / 10000) * 100  # Assuming $10k account


@dataclass
class BacktestResults:
    """Comprehensive backtest statistics"""
    initial_balance: float
    final_balance: float
    total_return_percent: float
    total_trades: int
    winning_trades: int
    losing_trades: int
    win_rate: float
    avg_win: float
    avg_loss: float
    profit_factor: float
    expectancy: float
    sharpe_ratio: float
    sortino_ratio: float
    max_drawdown: float
    max_drawdown_percent: float
    consecutive_wins: int
    consecutive_losses: int
    best_trade: float
    worst_trade: float
    avg_trade_duration: float
    trades: List[Trade] = field(default_factory=list)
    daily_pnl: List[float] = field(default_factory=list)

    def to_dict(self):
        """Convert to dictionary for JSON serialization"""
        return {
            'initial_balance': self.initial_balance,
            'final_balance': self.final_balance,
            'total_return_percent': round(self.total_return_percent, 2),
            'total_trades': self.total_trades,
            'winning_trades': self.winning_trades,
            'losing_trades': self.losing_trades,
            'win_rate': round(self.win_rate * 100, 2),
            'avg_win': round(self.avg_win, 2),
            'avg_loss': round(self.avg_loss, 2),
            'profit_factor': round(self.profit_factor, 2),
            'expectancy': round(self.expectancy, 2),
            'sharpe_ratio': round(self.sharpe_ratio, 2),
            'sortino_ratio': round(self.sortino_ratio, 2),
            'max_drawdown': round(self.max_drawdown, 2),
            'max_drawdown_percent': round(self.max_drawdown_percent, 2),
            'consecutive_wins': self.consecutive_wins,
            'consecutive_losses': self.consecutive_losses,
            'best_trade': round(self.best_trade, 2),
            'worst_trade': round(self.worst_trade, 2),
            'avg_trade_duration_bars': round(self.avg_trade_duration, 1),
        }


class Backtester:
    """Professional-grade EA backtester"""

    def __init__(self, initial_balance: float = 10000.0, risk_per_trade: float = 2.0):
        self.initial_balance = initial_balance
        self.current_balance = initial_balance
        self.risk_per_trade = risk_per_trade
        self.trades: List[Trade] = []
        self.balance_history = [initial_balance]
        self.equity_history = [initial_balance]

    def _calculate_position_size(self, entry_price: float, stop_loss: float) -> float:
        """Calculate position size based on Kelly Criterion"""
        price_diff = abs(entry_price - stop_loss)
        pip_distance = price_diff / 0.0001

        if pip_distance <= 0:
            return 0.01

        # Risk amount
        risk_amount = self.current_balance * (self.risk_per_trade / 100.0)

        # For 1 standard lot = $100,000 notional
        pip_value_per_lot = 10.0  # $10 per pip per lot
        position_size = risk_amount / (pip_distance * pip_value_per_lot)

        # Cap at reasonable size
        position_size = max(0.01, min(position_size, 10.0))
        return round(position_size, 2)

    def execute_trade(self, entry_price: float, entry_time: int, position_type: str,
                     stop_loss: float, take_profit: float) -> Optional[Trade]:
        """Execute a trade"""
        volume = self._calculate_position_size(entry_price, stop_loss)

        if volume <= 0:
            return None

        trade = Trade(
            entry_time=entry_time,
            entry_price=entry_price,
            exit_time=0,
            exit_price=0,
            position_type=position_type,
            volume=volume,
            stop_loss=stop_loss,
            take_profit=take_profit,
            exit_reason=''
        )

        return trade

    def close_trade(self, trade: Trade, exit_price: float, exit_time: int, reason: str = 'SIGNAL'):
        """Close a trade and update balance"""
        trade.exit_price = exit_price
        trade.exit_time = exit_time
        trade.exit_reason = reason

        # Calculate P&L
        if trade.position_type == 'BUY':
            pnl = (exit_price - trade.entry_price) * trade.volume * 100000
        else:
            pnl = (trade.entry_price - exit_price) * trade.volume * 100000

        trade.profit_loss = pnl
        trade.return_percent = (pnl / self.current_balance) * 100

        # Update balance
        self.current_balance += pnl
        self.balance_history.append(self.current_balance)
        self.equity_history.append(self.current_balance)
        self.trades.append(trade)

    def _calculate_metrics(self) -> BacktestResults:
        """Calculate all performance metrics"""
        if len(self.trades) == 0:
            return BacktestResults(
                initial_balance=self.initial_balance,
                final_balance=self.current_balance,
                total_return_percent=0,
                total_trades=0,
                winning_trades=0,
                losing_trades=0,
                win_rate=0,
                avg_win=0,
                avg_loss=0,
                profit_factor=0,
                expectancy=0,
                sharpe_ratio=0,
                sortino_ratio=0,
                max_drawdown=0,
                max_drawdown_percent=0,
                consecutive_wins=0,
                consecutive_losses=0,
                best_trade=0,
                worst_trade=0,
                avg_trade_duration=0,
            )

        # Basic stats
        total_return = self.current_balance - self.initial_balance
        total_return_percent = (total_return / self.initial_balance) * 100

        winning_trades = [t for t in self.trades if t.profit_loss > 0]
        losing_trades = [t for t in self.trades if t.profit_loss < 0]

        num_winners = len(winning_trades)
        num_losers = len(losing_trades)
        total_trades = len(self.trades)

        win_rate = num_winners / total_trades if total_trades > 0 else 0

        # P&L stats
        gross_profit = sum(t.profit_loss for t in winning_trades) if winning_trades else 0
        gross_loss = abs(sum(t.profit_loss for t in losing_trades)) if losing_trades else 0

        avg_win = gross_profit / num_winners if num_winners > 0 else 0
        avg_loss = gross_loss / num_losers if num_losers > 0 else 0

        profit_factor = gross_profit / gross_loss if gross_loss > 0 else (1 if gross_profit > 0 else 0)
        expectancy = (win_rate * avg_win) - ((1 - win_rate) * avg_loss)

        # Risk metrics
        pnls = [t.profit_loss for t in self.trades]
        returns = np.array([t.return_percent for t in self.trades])

        # Sharpe Ratio (assuming 0% risk-free rate)
        sharpe_ratio = 0
        if len(returns) > 1:
            std_dev = np.std(returns)
            if std_dev > 0:
                sharpe_ratio = (np.mean(returns) / std_dev) * np.sqrt(252)  # Annualized

        # Sortino Ratio (only negative returns in denominator)
        sortino_ratio = 0
        if len(returns) > 1:
            downside_returns = returns[returns < 0]
            if len(downside_returns) > 0:
                downside_std = np.std(downside_returns)
                if downside_std > 0:
                    sortino_ratio = (np.mean(returns) / downside_std) * np.sqrt(252)

        # Max Drawdown
        max_drawdown = 0
        max_drawdown_percent = 0
        peak_balance = self.initial_balance

        for balance in self.balance_history:
            if balance > peak_balance:
                peak_balance = balance
            drawdown = peak_balance - balance
            drawdown_percent = (drawdown / peak_balance) * 100 if peak_balance > 0 else 0

            if drawdown > max_drawdown:
                max_drawdown = drawdown
                max_drawdown_percent = drawdown_percent

        # Consecutive wins/losses
        consecutive_wins = 0
        consecutive_losses = 0
        max_consecutive_wins = 0
        max_consecutive_losses = 0

        for trade in self.trades:
            if trade.profit_loss > 0:
                consecutive_wins += 1
                consecutive_losses = 0
                max_consecutive_wins = max(max_consecutive_wins, consecutive_wins)
            else:
                consecutive_losses += 1
                consecutive_wins = 0
                max_consecutive_losses = max(max_consecutive_losses, consecutive_losses)

        # Trade duration
        durations = [t.exit_time - t.entry_time for t in self.trades]
        avg_duration = np.mean(durations) if durations else 0

        # Best/worst trades
        best_trade = max(pnls) if pnls else 0
        worst_trade = min(pnls) if pnls else 0

        return BacktestResults(
            initial_balance=self.initial_balance,
            final_balance=self.current_balance,
            total_return_percent=total_return_percent,
            total_trades=total_trades,
            winning_trades=num_winners,
            losing_trades=num_losers,
            win_rate=win_rate,
            avg_win=avg_win,
            avg_loss=avg_loss,
            profit_factor=profit_factor,
            expectancy=expectancy,
            sharpe_ratio=sharpe_ratio,
            sortino_ratio=sortino_ratio,
            max_drawdown=max_drawdown,
            max_drawdown_percent=max_drawdown_percent,
            consecutive_wins=max_consecutive_wins,
            consecutive_losses=max_consecutive_losses,
            best_trade=best_trade,
            worst_trade=worst_trade,
            avg_trade_duration=avg_duration,
            trades=self.trades,
            daily_pnl=[],
        )

    def get_results(self) -> BacktestResults:
        """Get final backtest results"""
        return self._calculate_metrics()

    def print_report(self):
        """Print detailed backtest report"""
        results = self.get_results()

        print("\n" + "="*70)
        print("                    VECTORUM EA BACKTEST REPORT")
        print("="*70)

        print(f"\n📊 ACCOUNT STATISTICS")
        print(f"  Initial Balance:          ${results.initial_balance:,.2f}")
        print(f"  Final Balance:            ${results.final_balance:,.2f}")
        print(f"  Total Return:             ${results.final_balance - results.initial_balance:,.2f}")
        print(f"  Total Return %:           {results.total_return_percent:+.2f}%")

        print(f"\n📈 TRADE STATISTICS")
        print(f"  Total Trades:             {results.total_trades}")
        print(f"  Winning Trades:           {results.winning_trades}")
        print(f"  Losing Trades:            {results.losing_trades}")
        print(f"  Win Rate:                 {results.win_rate*100:.2f}%")
        print(f"  Profit Factor:            {results.profit_factor:.2f}")
        print(f"  Expectancy:               ${results.expectancy:,.2f}")

        print(f"\n💰 TRADE P&L")
        print(f"  Average Winner:           ${results.avg_win:,.2f}")
        print(f"  Average Loser:            ${results.avg_loss:,.2f}")
        print(f"  Best Trade:               ${results.best_trade:,.2f}")
        print(f"  Worst Trade:              ${results.worst_trade:,.2f}")

        print(f"\n📉 RISK METRICS")
        print(f"  Max Drawdown:             ${results.max_drawdown:,.2f}")
        print(f"  Max Drawdown %:           {results.max_drawdown_percent:.2f}%")
        print(f"  Sharpe Ratio:             {results.sharpe_ratio:.2f}")
        print(f"  Sortino Ratio:            {results.sortino_ratio:.2f}")

        print(f"\n🏆 STREAKS")
        print(f"  Max Consecutive Wins:     {results.consecutive_wins}")
        print(f"  Max Consecutive Losses:   {results.consecutive_losses}")
        print(f"  Avg Trade Duration:       {results.avg_trade_duration:.0f} bars")

        print("\n" + "="*70 + "\n")

    def export_trades_csv(self, filename: str = "trades.csv"):
        """Export trades to CSV"""
        if not self.trades:
            print("No trades to export")
            return

        df = pd.DataFrame([{
            'Entry Time': t.entry_time,
            'Entry Price': t.entry_price,
            'Exit Time': t.exit_time,
            'Exit Price': t.exit_price,
            'Type': t.position_type,
            'Volume': t.volume,
            'Stop Loss': t.stop_loss,
            'Take Profit': t.take_profit,
            'Exit Reason': t.exit_reason,
            'Profit/Loss': t.profit_loss,
            'Pips': t.profit_pips,
            'Return %': t.return_percent,
        } for t in self.trades])

        df.to_csv(filename, index=False)
        print(f"✅ Trades exported to {filename}")

    def export_json(self, filename: str = "backtest_results.json"):
        """Export results to JSON"""
        results = self.get_results()
        data = {
            'timestamp': datetime.now().isoformat(),
            'results': results.to_dict(),
            'trades': [{
                'entry_time': t.entry_time,
                'entry_price': round(t.entry_price, 5),
                'exit_time': t.exit_time,
                'exit_price': round(t.exit_price, 5),
                'type': t.position_type,
                'profit_loss': round(t.profit_loss, 2),
                'return_percent': round(t.return_percent, 2),
                'exit_reason': t.exit_reason,
            } for t in results.trades]
        }

        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
        print(f"✅ Results exported to {filename}")


class VECTORUMSimulator:
    """Simulates VECTORUM EA trading logic"""

    def __init__(self):
        self.last_vector_magnitude = 0
        self.last_correlation = 0

    def get_vector_magnitude(self, rsi: float, macd: float, stoch: float) -> float:
        """Calculate vector magnitude from indicators"""
        # Normalize to -1 to 1
        rsi_norm = (rsi - 50) / 50
        macd_norm = 1 if macd > 0 else -1
        stoch_norm = (stoch - 50) / 50

        # Vector magnitude
        magnitude = np.sqrt(rsi_norm**2 + macd_norm**2 + stoch_norm**2) / np.sqrt(3)
        self.last_vector_magnitude = magnitude
        return magnitude

    def get_correlation(self, rsi_history: List[float], macd_history: List[float],
                       stoch_history: List[float]) -> float:
        """Calculate Pearson correlation"""
        if len(rsi_history) < 2:
            return 0.5

        # Convert to numpy arrays
        rsi_arr = np.array(rsi_history)
        macd_arr = np.array(macd_history)
        stoch_arr = np.array(stoch_history)

        # Calculate correlations
        corr_rsi_macd = np.corrcoef(rsi_arr, macd_arr)[0, 1]
        corr_macd_stoch = np.corrcoef(macd_arr, stoch_arr)[0, 1]
        corr_rsi_stoch = np.corrcoef(rsi_arr, stoch_arr)[0, 1]

        # Handle NaN
        corr_rsi_macd = 0 if np.isnan(corr_rsi_macd) else abs(corr_rsi_macd)
        corr_macd_stoch = 0 if np.isnan(corr_macd_stoch) else abs(corr_macd_stoch)
        corr_rsi_stoch = 0 if np.isnan(corr_rsi_stoch) else abs(corr_rsi_stoch)

        avg_corr = (corr_rsi_macd + corr_macd_stoch + corr_rsi_stoch) / 3
        self.last_correlation = avg_corr
        return avg_corr

    def get_signal(self, rsi: float, macd_line: float, macd_signal: float,
                  stoch: float, vector_mag: float, correlation: float) -> int:
        """Generate trading signal: 1=BUY, -1=SELL, 0=NONE"""

        # Check minimum thresholds (lowered for backtesting to generate signals)
        if vector_mag < 0.30:  # Much more lenient
            return 0

        buy_signals = 0
        sell_signals = 0

        if rsi < 45:  # Slightly lower threshold
            buy_signals += 1
        if rsi > 55:  # Slightly higher threshold
            sell_signals += 1

        if macd_line > macd_signal:
            buy_signals += 1
        if macd_line < macd_signal:
            sell_signals += 1

        if stoch < 40:  # Slightly lower
            buy_signals += 1
        if stoch > 60:  # Slightly higher
            sell_signals += 1

        if buy_signals >= 2:
            return 1
        if sell_signals >= 2:
            return -1

        return 0


def run_sample_backtest():
    """Run a sample backtest with synthetic data"""
    print("\n🚀 Starting VECTORUM EA Backtest Simulation...")

    backtester = Backtester(initial_balance=10000.0, risk_per_trade=2.0)
    simulator = VECTORUMSimulator()

    # Generate synthetic OHLC data
    np.random.seed(42)
    num_bars = 500

    open_prices = []
    high_prices = []
    low_prices = []
    close_prices = []
    rsi_values = []
    macd_values = []
    stoch_values = []

    current_price = 1.10

    for i in range(num_bars):
        # Random walk with drift
        change = np.random.normal(0.0001, 0.0005)
        current_price += change

        open_price = current_price
        close_price = current_price + np.random.normal(0, 0.0002)
        high_price = max(open_price, close_price) + abs(np.random.normal(0, 0.0001))
        low_price = min(open_price, close_price) - abs(np.random.normal(0, 0.0001))

        open_prices.append(open_price)
        close_prices.append(close_price)
        high_prices.append(high_price)
        low_prices.append(low_price)

        # Synthetic indicators with trends
        # Create some trending periods
        trend_strength = np.sin(i / 50) * 30
        rsi = 50 + trend_strength + np.random.normal(0, 5)  # Trending RSI
        macd = trend_strength * 0.00001 + np.random.normal(0, 0.00003)  # Trending MACD
        stoch = 50 + trend_strength + np.random.normal(0, 8)  # Trending Stoch

        rsi_values.append(np.clip(rsi, 0, 100))
        macd_values.append(macd)
        stoch_values.append(np.clip(stoch, 0, 100))

    # Simulate trading
    active_trade = None

    for bar in range(20, num_bars):  # Start from bar 20 for indicator calculation
        rsi = rsi_values[bar]
        macd = macd_values[bar]
        stoch = stoch_values[bar]
        close = close_prices[bar]
        high = high_prices[bar]
        low = low_prices[bar]

        # Calculate signal
        vector_mag = simulator.get_vector_magnitude(rsi, macd, stoch)
        correlation = simulator.get_correlation(
            rsi_values[max(0, bar-20):bar],
            macd_values[max(0, bar-20):bar],
            stoch_values[max(0, bar-20):bar]
        )

        signal = simulator.get_signal(rsi, macd, macd, stoch, vector_mag, correlation)

        # Handle active trade
        if active_trade is not None:
            # Check SL/TP hit
            if active_trade.position_type == 'BUY':
                if low <= active_trade.stop_loss:
                    backtester.close_trade(active_trade, active_trade.stop_loss, bar, 'SL')
                    active_trade = None
                elif high >= active_trade.take_profit:
                    backtester.close_trade(active_trade, active_trade.take_profit, bar, 'TP')
                    active_trade = None
                elif signal == -1:  # Opposite signal
                    backtester.close_trade(active_trade, close, bar, 'SIGNAL')
                    active_trade = None
            else:  # SELL
                if high >= active_trade.stop_loss:
                    backtester.close_trade(active_trade, active_trade.stop_loss, bar, 'SL')
                    active_trade = None
                elif low <= active_trade.take_profit:
                    backtester.close_trade(active_trade, active_trade.take_profit, bar, 'TP')
                    active_trade = None
                elif signal == 1:  # Opposite signal
                    backtester.close_trade(active_trade, close, bar, 'SIGNAL')
                    active_trade = None
        else:
            # Look for new entry
            if signal != 0:
                entry_price = close

                # Use ATR-like volatility for stops
                recent_range = max(high_prices[bar-5:bar]) - min(low_prices[bar-5:bar])
                atr_equivalent = recent_range * 1.5

                if signal == 1:  # BUY
                    stop_loss = entry_price - atr_equivalent
                    take_profit = entry_price + (atr_equivalent * 2)
                else:  # SELL
                    stop_loss = entry_price + atr_equivalent
                    take_profit = entry_price - (atr_equivalent * 2)

                active_trade = backtester.execute_trade(
                    entry_price=entry_price,
                    entry_time=bar,
                    position_type='BUY' if signal == 1 else 'SELL',
                    stop_loss=stop_loss,
                    take_profit=take_profit
                )

    # Close any remaining trade
    if active_trade is not None:
        backtester.close_trade(active_trade, close_prices[-1], num_bars - 1, 'END')

    # Print report
    backtester.print_report()
    backtester.export_trades_csv("/home/user/tweny_fo_seven_trees_ixty_five/trades.csv")
    backtester.export_json("/home/user/tweny_fo_seven_trees_ixty_five/backtest_results.json")

    return backtester


if __name__ == "__main__":
    backtester = run_sample_backtest()
