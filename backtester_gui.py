#!/usr/bin/env python3
"""
VECTORUM EA Backtesting GUI Application
Professional desktop application for backtesting trading strategies
"""

import tkinter as tk
from tkinter import ttk, messagebox, filedialog
import json
import threading
from datetime import datetime
from ea_backtester import Backtester, VECTORUMSimulator, run_sample_backtest
import numpy as np

class BacktesterGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("🚀 VECTORUM EA Backtester")
        self.root.geometry("1200x800")
        self.root.configure(bg="#1e1e1e")

        # Style configuration
        self.bg_dark = "#1e1e1e"
        self.bg_darker = "#0d0d0d"
        self.bg_panel = "#2d2d2d"
        self.fg_light = "#e0e0e0"
        self.fg_accent = "#00d4ff"
        self.fg_good = "#00ff41"
        self.fg_bad = "#ff3333"

        # Configure style
        style = ttk.Style()
        style.theme_use('clam')
        style.configure('TFrame', background=self.bg_dark)
        style.configure('TLabel', background=self.bg_dark, foreground=self.fg_light)
        style.configure('TButton', background=self.bg_panel, foreground=self.fg_light)
        style.map('TButton',
                 background=[('active', self.bg_darker)])

        self.current_results = None
        self.is_backtesting = False

        self.create_ui()

    def create_ui(self):
        """Create the main UI"""
        # Header
        header = tk.Frame(self.root, bg=self.bg_darker, height=60)
        header.pack(fill=tk.X, padx=0, pady=0)
        header.pack_propagate(False)

        title_label = tk.Label(header, text="⚡ VECTORUM EA Backtester",
                              font=("Arial", 24, "bold"),
                              bg=self.bg_darker, fg=self.fg_accent)
        title_label.pack(pady=10)

        # Main container
        main_container = ttk.Frame(self.root)
        main_container.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        # Left panel - Controls
        left_panel = ttk.Frame(main_container, width=300)
        left_panel.pack(side=tk.LEFT, fill=tk.BOTH, padx=5)

        # Right panel - Results
        right_panel = ttk.Frame(main_container)
        right_panel.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True, padx=5)

        self.create_control_panel(left_panel)
        self.create_results_panel(right_panel)

    def create_control_panel(self, parent):
        """Create control panel"""
        # Parameters section
        params_frame = tk.LabelFrame(parent, text="📊 Parameters",
                                    bg=self.bg_panel, fg=self.fg_accent,
                                    font=("Arial", 10, "bold"),
                                    padx=10, pady=10)
        params_frame.pack(fill=tk.X, pady=10)

        # Initial Balance
        tk.Label(params_frame, text="Initial Balance ($):", bg=self.bg_panel,
                fg=self.fg_light).pack(anchor=tk.W)
        self.balance_var = tk.StringVar(value="10000")
        balance_entry = ttk.Entry(params_frame, textvariable=self.balance_var, width=20)
        balance_entry.pack(anchor=tk.W, pady=5)

        # Risk Per Trade
        tk.Label(params_frame, text="Risk Per Trade (%):", bg=self.bg_panel,
                fg=self.fg_light).pack(anchor=tk.W)
        self.risk_var = tk.StringVar(value="2.0")
        risk_entry = ttk.Entry(params_frame, textvariable=self.risk_var, width=20)
        risk_entry.pack(anchor=tk.W, pady=5)

        # Vector Magnitude Threshold
        tk.Label(params_frame, text="Vector Magnitude Threshold:", bg=self.bg_panel,
                fg=self.fg_light).pack(anchor=tk.W)
        self.vector_var = tk.StringVar(value="0.50")
        vector_entry = ttk.Entry(params_frame, textvariable=self.vector_var, width=20)
        vector_entry.pack(anchor=tk.W, pady=5)

        # Correlation Threshold
        tk.Label(params_frame, text="Min Correlation:", bg=self.bg_panel,
                fg=self.fg_light).pack(anchor=tk.W)
        self.corr_var = tk.StringVar(value="0.50")
        corr_entry = ttk.Entry(params_frame, textvariable=self.corr_var, width=20)
        corr_entry.pack(anchor=tk.W, pady=5)

        # Buttons
        button_frame = ttk.Frame(parent)
        button_frame.pack(fill=tk.X, pady=10)

        self.backtest_btn = ttk.Button(button_frame, text="▶ Run Backtest",
                                      command=self.run_backtest)
        self.backtest_btn.pack(side=tk.LEFT, padx=5)

        export_btn = ttk.Button(button_frame, text="💾 Export CSV",
                               command=self.export_csv)
        export_btn.pack(side=tk.LEFT, padx=5)

        export_json_btn = ttk.Button(button_frame, text="📑 Export JSON",
                                    command=self.export_json)
        export_json_btn.pack(side=tk.LEFT, padx=5)

        # Status
        status_frame = tk.LabelFrame(parent, text="📈 Status",
                                    bg=self.bg_panel, fg=self.fg_accent,
                                    font=("Arial", 10, "bold"),
                                    padx=10, pady=10)
        status_frame.pack(fill=tk.X, pady=10)

        self.status_label = tk.Label(status_frame, text="Ready to backtest",
                                    bg=self.bg_panel, fg=self.fg_good,
                                    wraplength=250, justify=tk.LEFT)
        self.status_label.pack(anchor=tk.W)

        self.progress = ttk.Progressbar(status_frame, mode='indeterminate')
        self.progress.pack(fill=tk.X, pady=5)

    def create_results_panel(self, parent):
        """Create results display panel"""
        # Create notebook for tabs
        notebook = ttk.Notebook(parent)
        notebook.pack(fill=tk.BOTH, expand=True)

        # Summary tab
        summary_frame = ttk.Frame(notebook)
        notebook.add(summary_frame, text="📊 Summary")
        self.create_summary_tab(summary_frame)

        # Trades tab
        trades_frame = ttk.Frame(notebook)
        notebook.add(trades_frame, text="📋 Trades")
        self.create_trades_tab(trades_frame)

        # Metrics tab
        metrics_frame = ttk.Frame(notebook)
        notebook.add(metrics_frame, text="📈 Metrics")
        self.create_metrics_tab(metrics_frame)

    def create_summary_tab(self, parent):
        """Create summary statistics tab"""
        # Create scrollable frame
        canvas = tk.Canvas(parent, bg=self.bg_dark, highlightthickness=0)
        scrollbar = ttk.Scrollbar(parent, orient="vertical", command=canvas.yview)
        scrollable_frame = ttk.Frame(canvas)

        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )

        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)

        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

        self.summary_text = tk.Label(scrollable_frame, text="Run a backtest to see results",
                                    bg=self.bg_dark, fg=self.fg_light,
                                    justify=tk.LEFT, font=("Courier", 10))
        self.summary_text.pack(anchor=tk.W, padx=10, pady=10)

    def create_trades_tab(self, parent):
        """Create trades list tab"""
        # Create tree view
        columns = ("Entry", "Exit", "Type", "Profit", "Return %", "Reason")
        self.trades_tree = ttk.Treeview(parent, columns=columns, height=15, show='headings')

        # Define headings
        self.trades_tree.heading('#0', text='#')
        self.trades_tree.column('#0', width=30)

        for col in columns:
            self.trades_tree.heading(col, text=col)
            self.trades_tree.column(col, width=120)

        # Add scrollbar
        scrollbar = ttk.Scrollbar(parent, orient=tk.VERTICAL, command=self.trades_tree.yview)
        self.trades_tree.configure(yscroll=scrollbar.set)

        self.trades_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

    def create_metrics_tab(self, parent):
        """Create detailed metrics tab"""
        canvas = tk.Canvas(parent, bg=self.bg_dark, highlightthickness=0)
        scrollbar = ttk.Scrollbar(parent, orient="vertical", command=canvas.yview)
        scrollable_frame = ttk.Frame(canvas)

        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )

        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)

        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

        self.metrics_text = tk.Label(scrollable_frame, text="Run a backtest to see metrics",
                                    bg=self.bg_dark, fg=self.fg_light,
                                    justify=tk.LEFT, font=("Courier", 9))
        self.metrics_text.pack(anchor=tk.W, padx=10, pady=10)

    def run_backtest(self):
        """Run backtest in background thread"""
        if self.is_backtesting:
            messagebox.showwarning("Warning", "Backtest already running!")
            return

        try:
            initial_balance = float(self.balance_var.get())
            risk = float(self.risk_var.get())

            if initial_balance <= 0 or risk <= 0:
                messagebox.showerror("Error", "Please enter valid positive numbers")
                return
        except ValueError:
            messagebox.showerror("Error", "Invalid input values")
            return

        self.is_backtesting = True
        self.backtest_btn.config(state=tk.DISABLED)
        self.progress.start()
        self.status_label.config(text="⏳ Running backtest...", fg=self.fg_accent)

        # Run in background thread
        thread = threading.Thread(target=self._backtest_thread,
                                 args=(initial_balance, risk))
        thread.start()

    def _backtest_thread(self, initial_balance, risk):
        """Background thread for backtest"""
        try:
            # Run backtest
            backtester = Backtester(initial_balance, risk)
            simulator = VECTORUMSimulator()

            # Generate synthetic data
            np.random.seed(42)
            num_bars = 500

            close_prices = []
            high_prices = []
            low_prices = []
            rsi_values = []
            macd_values = []
            stoch_values = []

            current_price = 1.10

            for i in range(num_bars):
                change = np.random.normal(0.0001, 0.0005)
                current_price += change

                open_price = current_price
                close_price = current_price + np.random.normal(0, 0.0002)
                high_price = max(open_price, close_price) + abs(np.random.normal(0, 0.0001))
                low_price = min(open_price, close_price) - abs(np.random.normal(0, 0.0001))

                close_prices.append(close_price)
                high_prices.append(high_price)
                low_prices.append(low_price)

                trend_strength = np.sin(i / 50) * 30
                rsi = 50 + trend_strength + np.random.normal(0, 5)
                macd = trend_strength * 0.00001 + np.random.normal(0, 0.00003)
                stoch = 50 + trend_strength + np.random.normal(0, 8)

                rsi_values.append(np.clip(rsi, 0, 100))
                macd_values.append(macd)
                stoch_values.append(np.clip(stoch, 0, 100))

            # Simulate trading
            active_trade = None

            for bar in range(20, num_bars):
                rsi = rsi_values[bar]
                macd = macd_values[bar]
                stoch = stoch_values[bar]
                close = close_prices[bar]
                high = high_prices[bar]
                low = low_prices[bar]

                vector_mag = simulator.get_vector_magnitude(rsi, macd, stoch)
                correlation = simulator.get_correlation(
                    rsi_values[max(0, bar-20):bar],
                    macd_values[max(0, bar-20):bar],
                    stoch_values[max(0, bar-20):bar]
                )

                signal = simulator.get_signal(rsi, macd, macd, stoch, vector_mag, correlation)

                if active_trade is not None:
                    if active_trade.position_type == 'BUY':
                        if low <= active_trade.stop_loss:
                            backtester.close_trade(active_trade, active_trade.stop_loss, bar, 'SL')
                            active_trade = None
                        elif high >= active_trade.take_profit:
                            backtester.close_trade(active_trade, active_trade.take_profit, bar, 'TP')
                            active_trade = None
                        elif signal == -1:
                            backtester.close_trade(active_trade, close, bar, 'SIGNAL')
                            active_trade = None
                    else:
                        if high >= active_trade.stop_loss:
                            backtester.close_trade(active_trade, active_trade.stop_loss, bar, 'SL')
                            active_trade = None
                        elif low <= active_trade.take_profit:
                            backtester.close_trade(active_trade, active_trade.take_profit, bar, 'TP')
                            active_trade = None
                        elif signal == 1:
                            backtester.close_trade(active_trade, close, bar, 'SIGNAL')
                            active_trade = None
                else:
                    if signal != 0:
                        entry_price = close
                        recent_range = max(high_prices[bar-5:bar]) - min(low_prices[bar-5:bar])
                        atr_equivalent = recent_range * 1.5

                        if signal == 1:
                            stop_loss = entry_price - atr_equivalent
                            take_profit = entry_price + (atr_equivalent * 2)
                        else:
                            stop_loss = entry_price + atr_equivalent
                            take_profit = entry_price - (atr_equivalent * 2)

                        active_trade = backtester.execute_trade(
                            entry_price=entry_price,
                            entry_time=bar,
                            position_type='BUY' if signal == 1 else 'SELL',
                            stop_loss=stop_loss,
                            take_profit=take_profit
                        )

            if active_trade is not None:
                backtester.close_trade(active_trade, close_prices[-1], num_bars - 1, 'END')

            self.current_results = backtester.get_results()
            self.update_results_display()

            self.status_label.config(text="✅ Backtest completed successfully!",
                                    fg=self.fg_good)

        except Exception as e:
            messagebox.showerror("Error", f"Backtest failed: {str(e)}")
            self.status_label.config(text="❌ Backtest failed", fg=self.fg_bad)
        finally:
            self.is_backtesting = False
            self.backtest_btn.config(state=tk.NORMAL)
            self.progress.stop()

    def update_results_display(self):
        """Update results display"""
        if not self.current_results:
            return

        results = self.current_results

        # Update summary tab
        summary_text = f"""
╔════════════════════════════════════════════╗
║          BACKTEST SUMMARY REPORT            ║
╚════════════════════════════════════════════╝

📊 ACCOUNT STATISTICS
  Initial Balance:        ${results.initial_balance:>12,.2f}
  Final Balance:          ${results.final_balance:>12,.2f}
  Total Return:           ${results.final_balance - results.initial_balance:>12,.2f}
  Total Return %:         {results.total_return_percent:>12.2f}%

📈 TRADE STATISTICS
  Total Trades:           {results.total_trades:>12}
  Winning Trades:         {results.winning_trades:>12}
  Losing Trades:          {results.losing_trades:>12}
  Win Rate:               {results.win_rate*100:>12.2f}%
  Profit Factor:          {results.profit_factor:>12.2f}
  Expectancy:             ${results.expectancy:>12,.2f}

💰 TRADE P&L
  Average Winner:         ${results.avg_win:>12,.2f}
  Average Loser:          ${results.avg_loss:>12,.2f}
  Best Trade:             ${results.best_trade:>12,.2f}
  Worst Trade:            ${results.worst_trade:>12,.2f}

📉 RISK METRICS
  Max Drawdown:           ${results.max_drawdown:>12,.2f}
  Max Drawdown %:         {results.max_drawdown_percent:>12.2f}%
  Sharpe Ratio:           {results.sharpe_ratio:>12.2f}
  Sortino Ratio:          {results.sortino_ratio:>12.2f}

🏆 STREAKS
  Max Consecutive Wins:   {results.consecutive_wins:>12}
  Max Consecutive Losses: {results.consecutive_losses:>12}
  Avg Trade Duration:     {results.avg_trade_duration:>12.0f} bars
"""

        self.summary_text.config(text=summary_text, font=("Courier", 9))

        # Update trades tab
        for item in self.trades_tree.get_children():
            self.trades_tree.delete(item)

        for i, trade in enumerate(results.trades, 1):
            values = (
                f"#{trade.entry_time}",
                f"#{trade.exit_time}",
                trade.position_type,
                f"${trade.profit_loss:.2f}",
                f"{trade.return_percent:.2f}%",
                trade.exit_reason
            )
            self.trades_tree.insert('', 'end', iid=i, text=i, values=values)

        # Update metrics tab
        metrics_text = f"""
╔════════════════════════════════════════════╗
║         DETAILED PERFORMANCE METRICS        ║
╚════════════════════════════════════════════╝

PROFITABILITY ANALYSIS
  Gross Profit:           ${sum(t.profit_loss for t in results.trades if t.profit_loss > 0):,.2f}
  Gross Loss:             ${abs(sum(t.profit_loss for t in results.trades if t.profit_loss < 0)):,.2f}
  Net Profit:             ${sum(t.profit_loss for t in results.trades):,.2f}

RISK/REWARD ANALYSIS
  Profit Factor:          {results.profit_factor:.2f}x (Gross Profit / Gross Loss)
  Win Rate:               {results.win_rate*100:.2f}%
  Expectancy:             ${results.expectancy:.2f} per trade

VOLATILITY & RISK
  Max Drawdown:           ${results.max_drawdown:,.2f}
  Max Drawdown %:         {results.max_drawdown_percent:.2f}%
  Sharpe Ratio:           {results.sharpe_ratio:.2f} (Risk-Adjusted Returns)
  Sortino Ratio:          {results.sortino_ratio:.2f} (Downside Risk Only)

TRADE CHARACTERISTICS
  Consecutive Wins:       {results.consecutive_wins}
  Consecutive Losses:     {results.consecutive_losses}
  Avg Trade Duration:     {results.avg_trade_duration:.0f} bars
  Best Trade:             ${results.best_trade:.2f}
  Worst Trade:            ${results.worst_trade:.2f}

INTERPRETATION GUIDE
  Profit Factor > 2.0:    Excellent system
  Profit Factor 1.5-2.0:  Good system
  Sharpe Ratio > 1.0:     Good risk-adjusted returns
  Max Drawdown < 10%:     Excellent risk management
"""

        self.metrics_text.config(text=metrics_text, font=("Courier", 8))

    def export_csv(self):
        """Export trades to CSV"""
        if not self.current_results:
            messagebox.showwarning("Warning", "Run a backtest first!")
            return

        filepath = filedialog.asksaveasfilename(
            defaultextension=".csv",
            filetypes=[("CSV files", "*.csv"), ("All files", "*.*")]
        )

        if filepath:
            import pandas as pd
            df = pd.DataFrame([{
                'Entry Time': t.entry_time,
                'Entry Price': f"{t.entry_price:.5f}",
                'Exit Time': t.exit_time,
                'Exit Price': f"{t.exit_price:.5f}",
                'Type': t.position_type,
                'Volume': f"{t.volume:.2f}",
                'Profit/Loss': f"${t.profit_loss:.2f}",
                'Return %': f"{t.return_percent:.2f}%",
                'Exit Reason': t.exit_reason,
            } for t in self.current_results.trades])

            df.to_csv(filepath, index=False)
            messagebox.showinfo("Success", f"Trades exported to {filepath}")

    def export_json(self):
        """Export results to JSON"""
        if not self.current_results:
            messagebox.showwarning("Warning", "Run a backtest first!")
            return

        filepath = filedialog.asksaveasfilename(
            defaultextension=".json",
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")]
        )

        if filepath:
            data = {
                'timestamp': datetime.now().isoformat(),
                'results': self.current_results.to_dict(),
                'trades': [{
                    'entry_time': t.entry_time,
                    'entry_price': round(t.entry_price, 5),
                    'exit_time': t.exit_time,
                    'exit_price': round(t.exit_price, 5),
                    'type': t.position_type,
                    'profit_loss': round(t.profit_loss, 2),
                    'return_percent': round(t.return_percent, 2),
                    'exit_reason': t.exit_reason,
                } for t in self.current_results.trades]
            }

            with open(filepath, 'w') as f:
                json.dump(data, f, indent=2)

            messagebox.showinfo("Success", f"Results exported to {filepath}")


if __name__ == "__main__":
    root = tk.Tk()
    app = BacktesterGUI(root)
    root.mainloop()
