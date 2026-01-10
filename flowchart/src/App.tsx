import { useCallback, useState, useRef } from 'react';
import type { Node, Edge, NodeChange, EdgeChange, Connection } from '@xyflow/react';
import {
  ReactFlow,
  useNodesState,
  useEdgesState,
  Controls,
  Background,
  BackgroundVariant,
  MarkerType,
  applyNodeChanges,
  applyEdgeChanges,
  addEdge,
  Handle,
  Position,
  reconnectEdge,
} from '@xyflow/react';
import '@xyflow/react/dist/style.css';
import './App.css';

const nodeWidth = 260;
const nodeHeight = 80;

type Phase = 'entry' | 'setup' | 'coordination' | 'agents' | 'loop' | 'decision' | 'done';

const phaseColors: Record<Phase, { bg: string; border: string; icon: string }> = {
  entry: { bg: '#f0f9ff', border: '#0ea5e9', icon: '🚀' },
  setup: { bg: '#fef3c7', border: '#f59e0b', icon: '⚙️' },
  coordination: { bg: '#fef9c3', border: '#eab308', icon: '🟡' },
  agents: { bg: '#f0fdf4', border: '#22c55e', icon: '🤖' },
  loop: { bg: '#f5f5f5', border: '#6b7280', icon: '🔄' },
  decision: { bg: '#fee2e2', border: '#ef4444', icon: '❓' },
  done: { bg: '#d1fae5', border: '#10b981', icon: '✅' },
};

const allSteps: { id: string; label: string; description: string; phase: Phase; agent?: string; color?: string }[] = [
  // Entry
  { id: '1', label: 'Run /flow start', description: 'User initiates Maven Flow', phase: 'entry' },

  // Setup
  { id: '2', label: 'Load PRD', description: 'Read docs/prd.json for stories', phase: 'setup' },
  { id: '3', label: 'Read Progress', description: 'Load docs/progress.txt for patterns', phase: 'setup' },

  // Coordination
  { id: '4', label: 'flow-iteration agent (🟡)', description: 'Main coordinator picks story', phase: 'coordination' },

  // Agents (show all 4 Maven agents)
  { id: '5a', label: 'development-agent (🟢)', description: 'Steps 1,2,7,9: Foundation, pnpm, data, MCP', phase: 'agents', color: 'green' },
  { id: '5b', label: 'refactor-agent (🔵)', description: 'Steps 3,4,6: Structure, modularize, UI', phase: 'agents', color: 'blue' },
  { id: '5c', label: 'quality-agent (🟣)', description: 'Step 5: Type safety, @ aliases, NO gradients', phase: 'agents', color: 'purple' },
  { id: '5d', label: 'security-agent (🔴)', description: 'Steps 8,10: Auth flow, security audit', phase: 'agents', color: 'red' },

  // Implementation
  { id: '6', label: 'Implement Story', description: 'Agents coordinate to implement', phase: 'loop' },
  { id: '7', label: 'Quality Hooks', description: 'PostToolUse: Check any types, gradients', phase: 'loop' },
  { id: '8', label: 'Stop Hook', description: 'Pre-commit: Comprehensive check', phase: 'loop' },

  // Completion
  { id: '9', label: 'Commit Changes', description: 'feat: [Story ID] - [Title]', phase: 'loop' },
  { id: '10', label: 'Update PRD', description: 'Set passes: true in docs/prd.json', phase: 'loop' },
  { id: '11', label: 'Log Progress', description: 'Append learnings to docs/progress.txt', phase: 'loop' },

  // Decision
  { id: '12', label: 'All stories complete?', description: 'Check if all passes: true', phase: 'decision' },

  // Exit
  { id: '13', label: 'FLOW_COMPLETE', description: 'All stories implemented', phase: 'done' },
];

const notes = [
  {
    id: 'note-prd',
    appearsWithStep: 2,
    position: { x: 550, y: 80 },
    color: { bg: '#fef3c7', border: '#f59e0b' },
    content: `docs/prd.json
{
  "projectName": "My App",
  "branchName": "feature/auth",
  "stories": [
    {
      "id": "US-001",
      "title": "Add user authentication",
      "priority": 1,
      "passes": false,
      "acceptanceCriteria": [...]
    }
  ]
}`,
  },
  {
    id: 'note-agents',
    appearsWithStep: 5,
    position: { x: 600, y: 330 },
    color: { bg: '#f0fdf4', border: '#22c55e' },
    content: `Maven 10-Step Workflow:

🟢 development-agent
• Step 1: Import UI/create from scratch
• Step 2: npm → pnpm
• Step 7: Data layer
• Step 9: MCP integrations

🔵 refactor-agent
• Step 3: Feature-based structure
• Step 4: Modularize components
• Step 6: Centralize UI components

🟣 quality-agent
• Step 5: Type safety, @ aliases
• ZERO TOLERANCE: No 'any', no gradients

🔴 security-agent
• Step 8: Firebase + Supabase auth
• Step 10: Security & error handling`,
  },
  {
    id: 'note-hooks',
    appearsWithStep: 7,
    position: { x: 850, y: 550 },
    color: { bg: '#fce7f3', border: '#db2777' },
    content: `Automated Quality Hooks:

PostToolUse Hook:
• Checks after every Write/Edit
• 🚨 BLOCKS: 'any' types
• 🚨 BLOCKS: Gradients
• Flags: Relative imports
• Flags: Large components

Stop Hook:
• Runs before completing work
• Comprehensive codebase scan
• Blocks commit on violations
• Creates fix agent tasks`,
  },
  {
    id: 'note-architecture',
    appearsWithStep: 6,
    position: { x: 100, y: 500 },
    color: { bg: '#ede9fe', border: '#8b5cf6' },
    content: `Feature-Based Architecture:

src/
├── app/                    # Entry points
├── features/               # Isolated modules
│   ├── auth/              # Cannot import from
│   ├── dashboard/         # other features
│   └── [feature-name]/
├── shared/                # Shared code
│   ├── ui/                # @shared/ui
│   ├── api/               # Backend clients
│   └── utils/
└── [type: "app"]

Rules:
• Features → Cannot import from other features
• Use @shared/*, @features/* aliases
• NO relative imports
• NO gradients (solid colors only)`,
  },
];

function CustomNode({ data }: { data: { title: string; description: string; phase: Phase; agent?: string; color?: string } }) {
  const colors = phaseColors[data.phase];
  const borderColor = data.color ?
    (data.color === 'green' ? '#22c55e' :
     data.color === 'blue' ? '#3b82f6' :
     data.color === 'purple' ? '#a855f7' :
     data.color === 'red' ? '#ef4444' : colors.border)
    : colors.border;

  const bgColor = data.color ?
    (data.color === 'green' ? '#f0fdf4' :
     data.color === 'blue' ? '#eff6ff' :
     data.color === 'purple' ? '#faf5ff' :
     data.color === 'red' ? '#fef2f2' : colors.bg)
    : colors.bg;

  return (
    <div
      className="custom-node"
      style={{
        backgroundColor: bgColor,
        borderColor: borderColor,
      }}
    >
      <Handle type="target" position={Position.Top} id="top" />
      <Handle type="target" position={Position.Left} id="left" />
      <Handle type="source" position={Position.Right} id="right" />
      <Handle type="source" position={Position.Bottom} id="bottom" />
      <div className="node-icon">{colors.icon}</div>
      <div className="node-content">
        <div className="node-title">{data.title}</div>
        {data.description && <div className="node-description">{data.description}</div>}
      </div>
    </div>
  );
}

function NoteNode({ data }: { data: { content: string; color: { bg: string; border: string } } }) {
  return (
    <div
      className="note-node"
      style={{
        backgroundColor: data.color.bg,
        borderColor: data.color.border,
      }}
    >
      <pre>{data.content}</pre>
    </div>
  );
}

const nodeTypes = { custom: CustomNode, note: NoteNode };

const positions: { [key: string]: { x: number; y: number } } = {
  // Entry & Setup (left column)
  '1': { x: 50, y: 20 },
  '2': { x: 50, y: 130 },
  '3': { x: 50, y: 240 },

  // Coordination
  '4': { x: 50, y: 360 },

  // Agents (middle section - spread out)
  '5a': { x: 400, y: 320 },
  '5b': { x: 400, y: 420 },
  '5c': { x: 400, y: 520 },
  '5d': { x: 400, y: 620 },

  // Implementation (right side)
  '6': { x: 800, y: 320 },
  '7': { x: 800, y: 430 },
  '8': { x: 800, y: 540 },
  '9': { x: 800, y: 650 },
  '10': { x: 800, y: 760 },
  '11': { x: 800, y: 870 },

  // Decision & Exit
  '12': { x: 400, y: 870 },
  '13': { x: 400, y: 990 },

  // Notes
  ...Object.fromEntries(notes.map(n => [n.id, n.position])),
};

const edgeConnections: { source: string; target: string; sourceHandle?: string; targetHandle?: string; label?: string }[] = [
  // Entry & Setup
  { source: '1', target: '2', sourceHandle: 'bottom', targetHandle: 'top' },
  { source: '2', target: '3', sourceHandle: 'bottom', targetHandle: 'top' },
  { source: '3', target: '4', sourceHandle: 'bottom', targetHandle: 'top' },

  // Coordination to Agents (fan out)
  { source: '4', target: '5a', sourceHandle: 'right', targetHandle: 'left' },
  { source: '4', target: '5b', sourceHandle: 'right', targetHandle: 'left' },
  { source: '4', target: '5c', sourceHandle: 'right', targetHandle: 'left' },
  { source: '4', target: '5d', sourceHandle: 'right', targetHandle: 'left' },

  // Agents to Implementation
  { source: '5a', target: '6', sourceHandle: 'right', targetHandle: 'left' },
  { source: '5b', target: '6', sourceHandle: 'right', targetHandle: 'left' },
  { source: '5c', target: '6', sourceHandle: 'right', targetHandle: 'left' },
  { source: '5d', target: '6', sourceHandle: 'right', targetHandle: 'left' },

  // Implementation flow
  { source: '6', target: '7', sourceHandle: 'bottom', targetHandle: 'top' },
  { source: '7', target: '8', sourceHandle: 'bottom', targetHandle: 'top' },
  { source: '8', target: '9', sourceHandle: 'bottom', targetHandle: 'top' },
  { source: '9', target: '10', sourceHandle: 'bottom', targetHandle: 'top' },
  { source: '10', target: '11', sourceHandle: 'bottom', targetHandle: 'top' },
  { source: '11', target: '12', sourceHandle: 'bottom', targetHandle: 'left' },

  // Loop back
  { source: '12', target: '4', sourceHandle: 'top', targetHandle: 'bottom', label: 'More stories' },

  // Exit
  { source: '12', target: '13', sourceHandle: 'bottom', targetHandle: 'top', label: 'All done' },
];

function createNode(step: typeof allSteps[0], visible: boolean, position?: { x: number; y: number }): Node {
  return {
    id: step.id,
    type: 'custom',
    position: position || positions[step.id],
    data: {
      title: step.label,
      description: step.description,
      phase: step.phase,
      agent: step.agent,
      color: step.color,
    },
    style: {
      width: nodeWidth,
      height: nodeHeight,
      opacity: visible ? 1 : 0,
      transition: 'opacity 0.5s ease-in-out',
      pointerEvents: visible ? 'auto' : 'none',
    },
  };
}

function createEdge(conn: typeof edgeConnections[0], visible: boolean): Edge {
  return {
    id: `e${conn.source}-${conn.target}`,
    source: conn.source,
    target: conn.target,
    sourceHandle: conn.sourceHandle,
    targetHandle: conn.targetHandle,
    label: visible ? conn.label : undefined,
    animated: visible,
    style: {
      stroke: '#222',
      strokeWidth: 2,
      opacity: visible ? 1 : 0,
      transition: 'opacity 0.5s ease-in-out',
    },
    labelStyle: {
      fill: '#222',
      fontWeight: 600,
      fontSize: 14,
    },
    labelShowBg: true,
    labelBgPadding: [8, 4] as [number, number],
    labelBgStyle: {
      fill: '#fff',
      stroke: '#222',
      strokeWidth: 1,
    },
    markerEnd: {
      type: MarkerType.ArrowClosed,
      color: '#222',
    },
  };
}

function createNoteNode(note: typeof notes[0], visible: boolean, position?: { x: number; y: number }): Node {
  return {
    id: note.id,
    type: 'note',
    position: position || positions[note.id],
    data: { content: note.content, color: note.color },
    style: {
      opacity: visible ? 1 : 0,
      transition: 'opacity 0.5s ease-in-out',
      pointerEvents: visible ? 'auto' : 'none',
    },
    draggable: true,
    selectable: false,
    connectable: false,
  };
}

function App() {
  const [visibleCount, setVisibleCount] = useState(1);
  const nodePositions = useRef<{ [key: string]: { x: number; y: number } }>({ ...positions });

  const getNodes = (count: number) => {
    const stepNodes = allSteps.map((step, index) =>
      createNode(step, index < count, nodePositions.current[step.id])
    );
    const noteNodes = notes.map(note => {
      const noteVisible = count >= note.appearsWithStep;
      return createNoteNode(note, noteVisible, nodePositions.current[note.id]);
    });
    return [...stepNodes, ...noteNodes];
  };

  const initialNodes = getNodes(1);
  const initialEdges = edgeConnections.map((conn, index) =>
    createEdge(conn, index < 0)
  );

  const [nodes, setNodes] = useNodesState(initialNodes);
  const [edges, setEdges] = useEdgesState(initialEdges);

  const onNodesChange = useCallback(
    (changes: NodeChange[]) => {
      changes.forEach((change) => {
        if (change.type === 'position' && change.position) {
          nodePositions.current[change.id] = change.position;
        }
      });
      setNodes((nds) => applyNodeChanges(changes, nds));
    },
    [setNodes]
  );

  const onEdgesChange = useCallback(
    (changes: EdgeChange[]) => {
      setEdges((eds) => applyEdgeChanges(changes, eds));
    },
    [setEdges]
  );

  const onConnect = useCallback(
    (connection: Connection) => {
      setEdges((eds) => addEdge({
        ...connection,
        animated: true,
        style: { stroke: '#222', strokeWidth: 2 },
        markerEnd: { type: MarkerType.ArrowClosed, color: '#222' }
      }, eds));
    },
    [setEdges]
  );

  const onReconnect = useCallback(
    (oldEdge: Edge, newConnection: Connection) => {
      setEdges((eds) => reconnectEdge(oldEdge, newConnection, eds));
    },
    [setEdges]
  );

  const getEdgeVisibility = (conn: typeof edgeConnections[0], visibleStepCount: number) => {
    const sourceIndex = allSteps.findIndex(s => s.id === conn.source);
    const targetIndex = allSteps.findIndex(s => s.id === conn.target);
    return sourceIndex < visibleStepCount && targetIndex < visibleStepCount;
  };

  const handleNext = useCallback(() => {
    if (visibleCount < allSteps.length) {
      const newCount = visibleCount + 1;
      setVisibleCount(newCount);

      setNodes(getNodes(newCount));
      setEdges(
        edgeConnections.map((conn) =>
          createEdge(conn, getEdgeVisibility(conn, newCount))
        )
      );
    }
  }, [visibleCount, setNodes, setEdges]);

  const handlePrev = useCallback(() => {
    if (visibleCount > 1) {
      const newCount = visibleCount - 1;
      setVisibleCount(newCount);

      setNodes(getNodes(newCount));
      setEdges(
        edgeConnections.map((conn) =>
          createEdge(conn, getEdgeVisibility(conn, newCount))
        )
      );
    }
  }, [visibleCount, setNodes, setEdges]);

  const handleReset = useCallback(() => {
    setVisibleCount(1);
    nodePositions.current = { ...positions };
    setNodes(getNodes(1));
    setEdges(edgeConnections.map((conn, index) => createEdge(conn, index < 0)));
  }, [setNodes, setEdges]);

  return (
    <div className="app-container">
      <div className="header">
        <h1>How Maven Flow Works</h1>
        <p>Autonomous AI development system with coordinated specialist agents</p>
      </div>
      <div className="flow-container">
        <ReactFlow
          nodes={nodes}
          edges={edges}
          nodeTypes={nodeTypes}
          onNodesChange={onNodesChange}
          onEdgesChange={onEdgesChange}
          onConnect={onConnect}
          onReconnect={onReconnect}
          fitView
          fitViewOptions={{ padding: 0.2 }}
          nodesDraggable={true}
          nodesConnectable={true}
          edgesReconnectable={true}
          elementsSelectable={true}
          deleteKeyCode={['Backspace', 'Delete']}
          panOnDrag={true}
          panOnScroll={true}
          zoomOnScroll={true}
          zoomOnPinch={true}
          zoomOnDoubleClick={true}
          selectNodesOnDrag={false}
        >
          <Background variant={BackgroundVariant.Dots} gap={20} size={1} color="#ddd" />
          <Controls showInteractive={false} />
        </ReactFlow>
      </div>
      <div className="controls">
        <button onClick={handlePrev} disabled={visibleCount <= 1}>
          Previous
        </button>
        <span className="step-counter">
          Step {visibleCount} of {allSteps.length}
        </span>
        <button onClick={handleNext} disabled={visibleCount >= allSteps.length}>
          Next
        </button>
        <button onClick={handleReset} className="reset-btn">
          Reset
        </button>
      </div>
      <div className="instructions">
        <p>Click Next to reveal each step of the Maven Flow workflow</p>
        <p className="feature-highlights">
          <strong>Key Features:</strong> • 5 Coordinated Agents • Zero Tolerance Quality • Feature-Based Architecture • Professional UI Standards
        </p>
      </div>
    </div>
  );
}

export default App;
