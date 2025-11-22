"""
Nexus Mobile Web Server
Provides a beautiful mobile web interface for Nexus
"""

from flask import Flask, render_template, request, jsonify, send_from_directory
from flask_cors import CORS
import sys
from pathlib import Path
import asyncio
from threading import Thread

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from nexus import CentralNexus
from nexus.cores import CoderCore, LearnerCore, AgentSpawnerCore, SalesmanCore

app = Flask(__name__)
CORS(app)

# Initialize Nexus
print("🚀 Initializing Nexus...")
nexus = None


def init_nexus():
    """Initialize Nexus with all cores."""
    global nexus

    try:
        nexus = CentralNexus()

        # Initialize cores
        coder = CoderCore(
            config=nexus.config,
            ai_client=nexus.ai_client,
            vector_store=nexus.vector_store,
            ethical_guard=nexus.ethical_guard,
        )
        nexus.register_core("coder", coder)

        learner = LearnerCore(
            config=nexus.config,
            ai_client=nexus.ai_client,
            vector_store=nexus.vector_store,
        )
        nexus.register_core("learner", learner)

        agent_spawner = AgentSpawnerCore(
            config=nexus.config,
            ai_client=nexus.ai_client,
            vector_store=nexus.vector_store,
            learner_core=learner,
        )
        nexus.register_core("agent_spawner", agent_spawner)

        salesman = SalesmanCore(
            config=nexus.config,
            ai_client=nexus.ai_client,
            vector_store=nexus.vector_store,
            ethical_guard=nexus.ethical_guard,
            agent_spawner=agent_spawner,
        )
        nexus.register_core("salesman", salesman)

        print("✅ Nexus initialized successfully!")

    except Exception as e:
        print(f"❌ Error initializing Nexus: {e}")
        raise


# Initialize Nexus on startup
init_nexus()


@app.route('/')
def index():
    """Serve the main mobile web app."""
    return render_template('index.html')


@app.route('/manifest.json')
def manifest():
    """Serve PWA manifest."""
    return send_from_directory('static', 'manifest.json')


@app.route('/service-worker.js')
def service_worker():
    """Serve service worker."""
    return send_from_directory('static', 'service-worker.js')


@app.route('/api/chat', methods=['POST'])
async def chat():
    """Handle chat messages from mobile app."""
    try:
        data = request.json
        message = data.get('message', '')

        if not message:
            return jsonify({'error': 'No message provided'}), 400

        # Process message with Nexus
        response = await nexus.process_message(message)

        return jsonify({
            'success': True,
            'response': response
        })

    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/stats', methods=['GET'])
def stats():
    """Get system statistics."""
    try:
        stats = nexus.get_system_stats()
        return jsonify({
            'success': True,
            'stats': stats
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/goals', methods=['GET'])
def get_goals():
    """Get current goals."""
    try:
        goals = nexus.get_goals()
        return jsonify({
            'success': True,
            'goals': goals
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'nexus': 'ready',
        'provider': nexus.provider_type if nexus else 'unknown',
        'model': nexus.model if nexus else 'unknown'
    })


if __name__ == '__main__':
    print("\n" + "="*60)
    print("🚀 Nexus Mobile Web Server Starting...")
    print("="*60)
    print("\n📱 Access on your phone:")
    print("   1. Make sure phone is on same WiFi")
    print("   2. Go to: http://YOUR_IP:5000")
    print("   3. Tap 'Add to Home Screen' to install!\n")
    print("💡 Find your IP with: ifconfig or ipconfig\n")
    print("="*60 + "\n")

    # Run with async support
    app.run(
        host='0.0.0.0',  # Accessible from network
        port=5000,
        debug=True,
        threaded=True
    )
