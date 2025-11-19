# WoodCraft Designer

**The Ultimate App for Woodworkers, Hobbyists, and DIY Enthusiasts**

Create, customize, and bring your woodworking projects to life with WoodCraft Designer — a comprehensive web application for designing, planning, and documenting woodworking projects.

![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)
![Version](https://img.shields.io/badge/version-1.0.0-green.svg)

---

## Features

### 🎨 3D Modeling & Visualization
- **Interactive 3D workspace** with fully rotatable, zoomable camera
- **Real-time rendering** of wood pieces with realistic materials
- **Visual fastening representation** showing how pieces connect
- **Grid system** for accurate placement and alignment
- **Sky and lighting** for professional presentation

### 🪵 Customizable Wood Pieces
- **8 wood types** including Oak, Walnut, Maple, Cherry, Pine, Mahogany, Birch, and Cedar
- **Fully customizable dimensions** (length, width, thickness)
- **3D positioning** with X, Y, Z coordinates
- **Rotation controls** for complex assemblies
- **Color and texture** options for each piece

### 🔩 Fastenings and Joinery
- **10+ fastening types**:
  - Wood Screws
  - Nails & Brad Nails
  - Wood Glue
  - Dovetail Joints
  - Mortise & Tenon
  - Dowels
  - Biscuit Joints
  - Pocket Screws
  - And more!
- **Strength ratings** for each fastening type
- **Specifications** including size, length, diameter, and quantity
- **Visual representation** in 3D space

### 📋 Material List Generator
- **Automatic generation** of comprehensive material lists
- **Grouped by wood type** and dimensions
- **Quantity calculations** for efficient purchasing
- **Fastening inventory** with specifications
- **Board feet calculations** for cost estimation
- **Export to text file** for shopping

### ✂️ Project Planning
- **Step-by-step assembly guide** with detailed instructions
- **Tool requirements** for each step
- **Time estimates** for project completion
- **Safety notes** and best practices
- **Visual step navigation** with progress tracking

### 📁 Export Functionality
- **JSON export** for backup and sharing
- **CSV export** for spreadsheet applications
- **SVG blueprints** with top-down views
- **Cutting lists** with all dimensions and quantities
- **Multiple export formats** for different use cases

### 🛡️ Safety & Best Practices
- **30+ safety tips** covering all aspects of woodworking
- **Tool-specific guidance** for safe operation
- **Material handling** best practices
- **Finishing safety** including ventilation requirements
- **Context-aware tips** based on selected fastenings

---

## Technology Stack

### Frontend
- **React 18** - Modern UI framework
- **TypeScript** - Type-safe development
- **Vite** - Lightning-fast build tool
- **React Three Fiber** - 3D graphics with Three.js
- **@react-three/drei** - Useful helpers for R3F
- **Zustand** - Lightweight state management
- **Tailwind CSS** - Utility-first styling
- **Lucide React** - Beautiful icons

### Backend
- **Node.js** - Runtime environment
- **Express** - Web framework
- **TypeScript** - Type-safe development
- **MongoDB** - Document database
- **Mongoose** - ODM for MongoDB
- **Helmet** - Security middleware
- **CORS** - Cross-origin resource sharing
- **Compression** - Response compression

---

## Installation

### Prerequisites
- Node.js 18+ and npm
- MongoDB (optional - for data persistence)
- Modern web browser with WebGL support

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/woodcraft-designer.git
   cd woodcraft-designer
   ```

2. **Install dependencies**
   ```bash
   npm run install-all
   ```

3. **Configure environment** (optional)
   ```bash
   cd backend
   cp .env.example .env
   # Edit .env with your MongoDB connection string
   ```

4. **Start development servers**
   ```bash
   npm run dev
   ```

   This will start:
   - Frontend at `http://localhost:3000`
   - Backend at `http://localhost:5000`

### Production Build

```bash
# Build frontend
npm run build

# Start production server
npm start
```

---

## Usage Guide

### Creating a New Project

1. The app creates a default project on first load
2. Click **"Add Piece"** to add wood components
3. Configure dimensions, wood type, and position
4. Click **"Add Fastening"** to connect pieces
5. Select two pieces and choose fastening type

### 3D Workspace Controls

- **Rotate**: Left click + drag
- **Pan**: Right click + drag
- **Zoom**: Scroll wheel
- **Select**: Click on any piece or fastening
- **Toggle Grid**: Use the Grid button in toolbar

### Generating Materials List

1. Navigate to **Materials** view
2. Review automatically generated list
3. Click **Export List** to save as text file

### Assembly Instructions

1. Navigate to **Assembly** view
2. Follow step-by-step instructions
3. Review tools needed for each step
4. Check safety notes before proceeding
5. Use Previous/Next to navigate steps

### Exporting Your Project

1. Navigate to **Export** view
2. Choose export format:
   - **JSON** - Complete project data
   - **CSV** - Spreadsheet format
   - **SVG** - 2D blueprint
   - **Cutting List** - Formatted text file

---

## Project Structure

```
woodcraft-designer/
├── frontend/                 # React frontend application
│   ├── src/
│   │   ├── components/      # Reusable UI components
│   │   │   ├── Scene3D.tsx         # Main 3D canvas
│   │   │   ├── WoodPieceComponent.tsx
│   │   │   ├── FasteningComponent.tsx
│   │   │   ├── Sidebar.tsx
│   │   │   ├── Toolbar.tsx
│   │   │   └── modals/             # Modal dialogs
│   │   ├── pages/           # View components
│   │   │   ├── MaterialsView.tsx
│   │   │   ├── AssemblyView.tsx
│   │   │   └── ExportView.tsx
│   │   ├── hooks/           # Custom React hooks
│   │   │   └── useStore.ts         # Zustand state management
│   │   ├── types/           # TypeScript type definitions
│   │   ├── styles/          # CSS styles
│   │   └── App.tsx          # Main application component
│   ├── public/              # Static assets
│   └── package.json
├── backend/                 # Express backend API
│   ├── src/
│   │   ├── controllers/     # Request handlers
│   │   ├── models/          # MongoDB models
│   │   ├── routes/          # API routes
│   │   └── index.ts         # Server entry point
│   └── package.json
├── shared/                  # Shared TypeScript types
│   └── types/
└── package.json            # Root package.json
```

---

## API Endpoints

### Projects
- `GET /api/projects` - Get all projects
- `GET /api/projects/:id` - Get project by ID
- `POST /api/projects` - Create new project
- `PUT /api/projects/:id` - Update project
- `DELETE /api/projects/:id` - Delete project
- `POST /api/projects/:id/material-list` - Generate material list
- `POST /api/projects/:id/cutting-plan` - Generate cutting plan
- `POST /api/projects/:id/assembly-guide` - Generate assembly guide

### Materials
- `GET /api/materials/wood-types` - Get wood type information
- `GET /api/materials/fastening-types` - Get fastening type information

### Safety
- `GET /api/safety/tips` - Get safety tips
- `GET /api/safety/tips?relatedTo=screw` - Get filtered safety tips

---

## Development

### Running Tests
```bash
# Frontend tests
cd frontend
npm test

# Backend tests
cd backend
npm test
```

### Code Style
- ESLint for linting
- Prettier for formatting
- TypeScript strict mode enabled

### Contributing
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## Features Roadmap

### Planned Features
- [ ] AR visualization for mobile devices
- [ ] Collaborative editing with real-time sync
- [ ] Advanced cutting optimization algorithms
- [ ] Cost estimation with material price database
- [ ] Project templates library
- [ ] CAD format import/export (DXF, STL)
- [ ] Photo-realistic rendering
- [ ] Material texture library
- [ ] Community project sharing
- [ ] Mobile app (iOS/Android)

---

## Browser Support

- Chrome/Edge 90+
- Firefox 88+
- Safari 14+
- Opera 76+

**Note:** WebGL support required for 3D visualization

---

## Performance Tips

- Use fewer pieces for complex projects to maintain smooth 3D performance
- Export large projects as JSON and load them as needed
- Clear browser cache if experiencing slowdowns
- Use Grid toggle to improve rendering performance

---

## Troubleshooting

### 3D View Not Loading
- Ensure WebGL is enabled in your browser
- Update graphics drivers
- Try a different browser

### Backend Connection Issues
- Check that MongoDB is running (if using database)
- Verify backend is running on port 5000
- Check CORS settings in backend

### Performance Issues
- Reduce number of pieces in scene
- Turn off grid if not needed
- Close other browser tabs

---

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- **Three.js** - 3D graphics library
- **React Three Fiber** - React renderer for Three.js
- **Tailwind CSS** - Utility-first CSS framework
- **Lucide** - Beautiful open-source icons

---

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Email: support@woodcraftdesigner.com (coming soon)
- Documentation: [Wiki](https://github.com/yourusername/woodcraft-designer/wiki)

---

## Screenshots

### 3D Workspace
![3D Workspace](docs/screenshots/workspace.png)

### Material List
![Material List](docs/screenshots/materials.png)

### Assembly Guide
![Assembly Guide](docs/screenshots/assembly.png)

### Export Options
![Export](docs/screenshots/export.png)

---

**Made with ❤️ for woodworkers everywhere**

Happy Building! 🪵🔨
