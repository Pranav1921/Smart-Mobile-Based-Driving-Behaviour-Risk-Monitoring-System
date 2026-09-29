@echo off
echo Sending New Order to SmartDrive Mobile App...
cd backend
npx ts-node src/scripts/send_order.ts %1 %2 %3 %4 %5 %6
echo Done!
