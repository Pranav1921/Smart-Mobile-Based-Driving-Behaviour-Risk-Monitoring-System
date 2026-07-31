import { Router, Request, Response } from 'express';
import fs from 'fs';
import path from 'path';

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
router.get('/', (req: Request, res: Response) => {
  const orders = readOrders();
  res.json({ success: true, data: orders });
});

// POST /orders
router.post('/', (req: Request, res: Response) => {
  const { customerName, items, amount, deliveryLocation } = req.body;
  
  if (!customerName || !items || !deliveryLocation) {
    return res.status(400).json({ success: false, message: 'Missing fields' });
  }

  const orders = readOrders();
  const newOrder = {
    id: `ord_${Date.now()}`,
    customerName,
    items,
    amount: amount || 0,
    status: 'PENDING',
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

export default router;
