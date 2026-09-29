import { Router, Request, Response } from 'express';
import fs from 'fs';
import path from 'path';
import { socketManager } from '../sockets/socket.manager';

const router = Router();
const ORDERS_FILE = path.join(__dirname, '../../orders.json');

// Helper to read orders
const readOrders = () => {
  if (!fs.existsSync(ORDERS_FILE)) {
    return [];
  }
  try {
    return JSON.parse(fs.readFileSync(ORDERS_FILE, 'utf-8'));
  } catch (err) {
    return [];
  }
};

// Helper to write orders
const writeOrders = (orders: any[]) => {
  fs.writeFileSync(ORDERS_FILE, JSON.stringify(orders, null, 2), 'utf-8');
};

// GET /orders
router.get('/', (_req: Request, res: Response) => {
  const orders = readOrders();
  res.json({ success: true, data: orders });
});

// GET /orders/pending
router.get('/pending', (_req: Request, res: Response) => {
  const orders = readOrders();
  const pending = orders.filter((o: any) => o.status === 'PENDING');
  res.json({ success: true, data: pending });
});

// POST /orders
router.post('/', (req: Request, res: Response) => {
  const { customerName, items, amount, deliveryLocation, deliveryFrom } = req.body;
  
  if (!customerName || !items || !deliveryLocation) {
    res.status(400).json({ success: false, message: 'Missing fields' });
    return;
  }

  const orders = readOrders();
  const newOrder = {
    id: `ord_${Date.now()}`,
    customerName,
    items,
    amount: amount || 0,
    status: 'PENDING',
    deliveryFrom: deliveryFrom || 'Main Logistics Depot',
    deliveryLocation: {
      latitude: parseFloat(deliveryLocation.latitude) || 19.0760, // default Mumbai
      longitude: parseFloat(deliveryLocation.longitude) || 72.8777,
      address: deliveryLocation.address || 'Mumbai, Maharashtra'
    },
    createdAt: new Date().toISOString()
  };

  orders.push(newOrder);
  writeOrders(orders);

  res.status(201).json({ success: true, data: newOrder });
});

// POST /orders/:id/assign — push job to a specific driver via socket
router.post('/:id/assign', (req: Request, res: Response) => {
  const { id } = req.params;
  const { driverId, driverName } = req.body;

  if (!driverId) {
    res.status(400).json({ success: false, message: 'driverId is required' });
    return;
  }

  const orders = readOrders();
  const orderIdx = orders.findIndex((o: any) => o.id === id);

  if (orderIdx === -1) {
    res.status(404).json({ success: false, message: 'Order not found' });
    return;
  }

  // Update order state
  orders[orderIdx].status = 'ASSIGNED';
  orders[orderIdx].assignedDriverId = driverId;
  orders[orderIdx].assignedDriverName = driverName || 'Driver';
  orders[orderIdx].assignedAt = new Date().toISOString();
  writeOrders(orders);

  const order = orders[orderIdx];

  // Push job_assigned to the driver's personal socket room
  socketManager.sendToUser(driverId, 'job_assigned', {
    orderId: order.id,
    customerName: order.customerName,
    items: order.items,
    amount: order.amount,
    deliveryFrom: order.deliveryFrom || 'Main Dispatch Hub',
    deliveryTo: order.deliveryLocation?.address || 'Customer Address',
    deliveryLocation: order.deliveryLocation,
    assignedAt: order.assignedAt,
  });

  // Also broadcast status update to admin dashboard org room
  socketManager.broadcastToOrg('demo-org', 'order_assigned', {
    orderId: order.id,
    driverId,
    driverName: driverName || 'Driver',
    status: 'ASSIGNED',
  });

  res.json({ success: true, data: order });
});

export default router;
