#!/usr/bin/env python3
"""
VECTORUM PRO Backtester
Advanced backtesting with smart exits and market condition detection
"""

import numpy as np
import pandas as pd
from datetime import datetime
from dataclasses import dataclass, field
from typing import List, Tuple
import json

@dataclass
class Trade:
    """Trade data"""
    entry_time: int
    entry_price: float
    exit_time: int
    exit_price: float
    position_type: str
    volume: float
    stop_loss: float
    take_profit: float
    exit_reason: str
    profit_loss: float = 0.0
    profit_pips: float = 0.0
    return_percent: float = 0.0

    def __post_init__(self):
        if self.position_type == 'BUY':
            self.profit_loss = (self.exit_price - self.entry_price) * self.volume * 100000
            self.profit_pips = (self.exit_price - self.entry_price) / 0.0001
        else:
            self.profit_loss = (self.entry_price - self.exit_price) * self.volume * 100000
            self.profit_pips = (self.entry_price - self.exit_price) / 0.0001

        self.return_percent = (self.profit_loss / 10000) * 100


@dataclass
class BacktestResults:
    """Backtest statistics"""
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

    # PRO specific metrics
    smart_exit_trades: int = 0
    breakeven_protected: int = 0
    trending_market_trades: int = 0
    choppy_market_avoided: int = 0

    def to_dict(self):
        return {
            'initial_balance': self.initial_balance,
            'final_balance': round(self.final_balance, 2),
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
            'smart_exit_trades': self.smart_exit_trades,
            'breakeven_protected': self.breakeven_protected,
            'trending_market_trades': self.trending_market_trades,
            'choppy_market_avoided': self.choppy_market_avoided,
        }


class MarketConditionDetector:
    """Detects trending vs choppy markets"""

    def __init__(self, lookback=20):
        self.lookback = lookback

    def detect(self, high_prices: List[float], low_prices: List[float], close_prices: List[float]) -> int:
        """
        Returns: 1 = Trending UP, -1 = Trending DOWN, 0 = CHOPPY
        """
        if len(high_prices) < self.lookback:
            return 2  # Unknown

        # Calculate ATR equivalent
        tr_list = []
        for i in range(len(high_prices) - 1, max(len(high_prices) - self.lookback - 1, -1), -1):
            tr = max(
                high_prices[i] - low_prices[i],
                abs(high_prices[i] - close_prices[i - 1]) if i > 0 else 0,
                abs(low_prices[i] - close_prices[i - 1]) if i > 0 else 0
            )
            tr_list.append(tr)

        atr = np.mean(tr_list[-self.lookback:]) if tr_list else 0.00005

        # Calculate average range
        ranges = [high_prices[i] - low_prices[i] for i in range(len(high_prices) - self.lookback, len(high_prices))]
        avg_range = np.mean(ranges) if ranges else 0.00005

        # Volatility ratio (trend strength)
        volatility_ratio = avg_range / atr if atr > 0 else 0

        # Check trend direction
        sma_fast = np.mean(close_prices[-5:])
        sma_slow = np.mean(close_prices[-20:]) if len(close_prices) >= 20 else sma_fast

        current_close = close_prices[-1]

        if volatility_ratio > 0.8:  # Trending market
            if current_close > sma_fast and sma_fast > sma_slow:
                return 1  # Trending UP
            elif current_close < sma_fast and sma_fast < sma_slow:
                return -1  # Trending DOWN

        return 0  # CHOPPY


class VECTORUMProSimulator:
    """VECTORUM PRO strategy simulator"""

    def __init__(self):
        self.market_detector = MarketConditionDetector()
        self.last_market_condition = 0

    def get_vector_magnitude(self, rsi: float, macd: float, stoch: float) -> float:
        rsi_norm = (rsi - 50) / 50
        macd_norm = 1 if macd > 0 else -1
        stoch_norm = (stoch - 50) / 50

        magnitude = np.sqrt(rsi_norm**2 + macd_norm**2 + stoch_norm**2) / np.sqrt(3)
        return min(1.0, magnitude)

    def get_signal(self, rsi: float, macd: float, macd_signal: float, stoch: float) -> int:
        buy_signals = 0
        sell_signals = 0

        if rsi < 45: buy_signals += 1
        if rsi > 55: sell_signals += 1
        if macd > macd_signal: buy_signals += 1
        if macd < macd_signal: sell_signals += 1
        if stoch < 40: buy_signals += 1
        if stoch > 60: sell_signals += 1

        if buy_signals >= 2: return 1
        if sell_signals >= 2: return -1
        return 0

    def detect_market(self, high: List[float], low: List[float], close: List[float]) -> int:
        self.last_market_condition = self.market_detector.detect(high, low, close)
        return self.last_market_condition


class ProBacktester:
    """Enhanced backtester with smart exits"""

    def __init__(self, initial_balance=10000, risk_per_trade=2.0,
                 use_smart_exits=True, use_market_detector=True):
        self.initial_balance = initial_balance
        self.current_balance = initial_balance
        self.risk_per_trade = risk_per_trade
        self.use_smart_exits = use_smart_exits
        self.use_market_detector = use_market_detector
        self.trades = []
        self.balance_history = [initial_balance]
        self.smart_exits_count = 0
        self.breakeven_count = 0

    def execute_trade(self, entry_price: float, entry_time: int, position_type: str,
                     stop_loss: float, take_profit: float) -> Trade:
        """Execute trade"""
        risk_amount = self.current_balance * (self.risk_per_trade / 100.0)
        pip_distance = abs(entry_price - stop_loss) / 0.0001

        if pip_distance <= 0:
            return None

        pip_value = 10.0  # Standard pip value
        volume = risk_amount / (pip_distance * pip_value)
        volume = max(0.01, min(volume, 10.0))

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

    def close_trade(self, trade: Trade, exit_price: float, exit_time: int, reason: str):
        """Close trade"""
        trade.exit_price = exit_price
        trade.exit_time = exit_time
        trade.exit_reason = reason

        if trade.position_type == 'BUY':
            pnl = (exit_price - trade.entry_price) * trade.volume * 100000
        else:
            pnl = (trade.entry_price - exit_price) * trade.volume * 100000

        trade.profit_loss = pnl
        trade.return_percent = (pnl / self.current_balance) * 100

        self.current_balance += pnl
        self.balance_history.append(self.current_balance)
        self.trades.append(trade)

        if reason in ['BREAKEVEN', 'TRAILING_STOP', 'REVERSAL', 'MARKET_CHANGE']:
            self.smart_exits_count += 1
            if reason == 'BREAKEVEN':
                self.breakeven_count += 1

    def calculate_metrics(self) -> BacktestResults:
        """Calculate all metrics"""
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

        total_return = self.current_balance - self.initial_balance
        total_return_percent = (total_return / self.initial_balance) * 100

        winners = [t for t in self.trades if t.profit_loss > 0]
        losers = [t for t in self.trades if t.profit_loss < 0]

        num_winners = len(winners)
        num_losers = len(losers)
        total_trades = len(self.trades)
        win_rate = num_winners / total_trades if total_trades > 0 else 0

        gross_profit = sum(t.profit_loss for t in winners) if winners else 0
        gross_loss = abs(sum(t.profit_loss for t in losers)) if losers else 0

        avg_win = gross_profit / num_winners if num_winners > 0 else 0
        avg_loss = gross_loss / num_losers if num_losers > 0 else 0

        profit_factor = gross_profit / gross_loss if gross_loss > 0 else (1 if gross_profit > 0 else 0)
        expectancy = (win_rate * avg_win) - ((1 - win_rate) * avg_loss)

        # Sharpe/Sortino
        returns = np.array([t.return_percent for t in self.trades])
        sharpe = 0
        if len(returns) > 1:
            std_dev = np.std(returns)
            if std_dev > 0 and not np.isnan(std_dev):
                sharpe = (np.mean(returns) / std_dev) * np.sqrt(252)
            sharpe = max(-10, min(10, sharpe))  # Clamp to reasonable range

        sortino = 0
        downside_returns = returns[returns < 0]
        if len(downside_returns) > 0:
            down_std = np.std(downside_returns)
            if down_std > 0 and not np.isnan(down_std):
                sortino = (np.mean(returns) / down_std) * np.sqrt(252)
            sortino = max(-10, min(10, sortino))  # Clamp to reasonable range

        # Max drawdown
        max_dd = 0
        max_dd_pct = 0
        peak = self.initial_balance
        for bal in self.balance_history:
            if bal > peak:
                peak = bal
            dd = peak - bal
            dd_pct = (dd / peak) * 100 if peak > 0 else 0
            if dd > max_dd:
                max_dd = dd
                max_dd_pct = dd_pct

        # Streaks
        max_wins = 0
        max_losses = 0
        current_wins = 0
        current_losses = 0

        for trade in self.trades:
            if trade.profit_loss > 0:
                current_wins += 1
                current_losses = 0
                max_wins = max(max_wins, current_wins)
            else:
                current_losses += 1
                current_wins = 0
                max_losses = max(max_losses, current_losses)

        durations = [t.exit_time - t.entry_time for t in self.trades]
        avg_duration = np.mean(durations) if durations else 0

        best = max([t.profit_loss for t in self.trades]) if self.trades else 0
        worst = min([t.profit_loss for t in self.trades]) if self.trades else 0

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
            sharpe_ratio=sharpe,
            sortino_ratio=sortino,
            max_drawdown=max_dd,
            max_drawdown_percent=max_dd_pct,
            consecutive_wins=max_wins,
            consecutive_losses=max_losses,
            best_trade=best,
            worst_trade=worst,
            avg_trade_duration=avg_duration,
            trades=self.trades,
            smart_exit_trades=self.smart_exits_count,
            breakeven_protected=self.breakeven_count,
        )

    def print_report(self):
        """Print detailed report"""
        results = self.calculate_metrics()

        print("\n" + "="*75)
        print("              🚀 VECTORUM PRO BACKTEST REPORT 🚀")
        print("="*75)

        print(f"\n💰 ACCOUNT STATISTICS")
        print(f"  Initial Balance:          ${results.initial_balance:,.2f}")
        print(f"  Final Balance:            ${results.final_balance:,.2f}")
        print(f"  Total Return:             ${results.final_balance - results.initial_balance:,.2f}")
        print(f"  Total Return %:           {results.total_return_percent:+.2f}%")

        print(f"\n📊 TRADE STATISTICS")
        print(f"  Total Trades:             {results.total_trades}")
        print(f"  Winning Trades:           {results.winning_trades}")
        print(f"  Losing Trades:            {results.losing_trades}")
        print(f"  Win Rate:                 {results.win_rate*100:.2f}%")
        print(f"  Profit Factor:            {results.profit_factor:.2f}")
        print(f"  Expectancy:               ${results.expectancy:,.2f}")

        print(f"\n💎 SMART EXIT STATISTICS")
        print(f"  Smart Exits Used:         {results.smart_exit_trades}")
        print(f"  Breakeven Protected:      {results.breakeven_protected}")
        print(f"  Exit Rate:                {(results.smart_exit_trades/results.total_trades*100) if results.total_trades > 0 else 0:.1f}%")

        print(f"\n📈 P&L ANALYSIS")
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

        print("\n" + "="*75 + "\n")

    def export_json(self, filename="backtest_pro_results.json"):
        results = self.calculate_metrics()
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


def run_pro_backtest():
    """Run VECTORUM PRO backtest"""
    print("\n🚀 Starting VECTORUM PRO Backtest (EURUSD)...")

    backtester = ProBacktester(
        initial_balance=10000,
        risk_per_trade=2.0,
        use_smart_exits=True,
        use_market_detector=True
    )
    simulator = VECTORUMProSimulator()

    # Generate synthetic trending data for EURUSD
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
        # Same data generation as working backtester
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

        # Synthetic indicators with trends (same as working backtest)
        trend_strength = np.sin(i / 50) * 30
        rsi = 50 + trend_strength + np.random.normal(0, 5)
        macd = trend_strength * 0.00001 + np.random.normal(0, 0.00003)
        stoch = 50 + trend_strength + np.random.normal(0, 8)

        rsi_values.append(np.clip(rsi, 0, 100))
        macd_values.append(macd)
        stoch_values.append(np.clip(stoch, 0, 100))

    # Simulate trading
    active_trade = None
    market_conditions = []

    for bar in range(20, num_bars):
        market = simulator.detect_market(
            high_prices[max(0, bar-20):bar+1],
            low_prices[max(0, bar-20):bar+1],
            close_prices[max(0, bar-20):bar+1]
        )
        market_conditions.append(market)

        rsi = rsi_values[bar]
        macd = macd_values[bar]
        stoch = stoch_values[bar]
        close = close_prices[bar]
        high = high_prices[bar]
        low = low_prices[bar]

        vector_mag = simulator.get_vector_magnitude(rsi, macd, stoch)
        signal = simulator.get_signal(rsi, macd, macd, stoch)

        if active_trade:
            # Check exits
            should_exit = False
            exit_reason = ""

            if active_trade.position_type == 'BUY':
                if low <= active_trade.stop_loss:
                    backtester.close_trade(active_trade, active_trade.stop_loss, bar, 'SL')
                    active_trade = None
                    should_exit = True
                elif high >= active_trade.take_profit:
                    backtester.close_trade(active_trade, active_trade.take_profit, bar, 'TP')
                    active_trade = None
                    should_exit = True
                # Smart exit: reversal or market change
                elif signal == -1 and (close - active_trade.entry_price) / 0.0001 > 0:
                    backtester.close_trade(active_trade, close, bar, 'REVERSAL')
                    active_trade = None
                    should_exit = True

            else:  # SELL
                if high >= active_trade.stop_loss:
                    backtester.close_trade(active_trade, active_trade.stop_loss, bar, 'SL')
                    active_trade = None
                    should_exit = True
                elif low <= active_trade.take_profit:
                    backtester.close_trade(active_trade, active_trade.take_profit, bar, 'TP')
                    active_trade = None
                    should_exit = True
                elif signal == 1 and (active_trade.entry_price - close) / 0.0001 > 0:
                    backtester.close_trade(active_trade, close, bar, 'REVERSAL')
                    active_trade = None
                    should_exit = True

        else:
            if signal != 0 and vector_mag > 0.30:  # Lowered threshold
                entry_price = close
                recent_range = max(high_prices[max(0, bar-5):bar]) - min(low_prices[max(0, bar-5):bar])
                atr_equiv = recent_range * 1.5

                if signal == 1:
                    stop_loss = entry_price - atr_equiv
                    take_profit = entry_price + (atr_equiv * 2.0)
                else:
                    stop_loss = entry_price + atr_equiv
                    take_profit = entry_price - (atr_equiv * 2.0)

                active_trade = backtester.execute_trade(
                    entry_price=entry_price,
                    entry_time=bar,
                    position_type='BUY' if signal == 1 else 'SELL',
                    stop_loss=stop_loss,
                    take_profit=take_profit
                )

    if active_trade:
        backtester.close_trade(active_trade, close_prices[-1], num_bars - 1, 'END')

    backtester.print_report()
    backtester.export_json("/home/user/tweny_fo_seven_trees_ixty_five/backtest_pro_results.json")

    return backtester


if __name__ == "__main__":
    backtester = run_pro_backtest()
