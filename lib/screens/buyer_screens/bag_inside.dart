/*
Container(
padding: const EdgeInsets.all(16.0),
decoration: BoxDecoration(
color: Colors.grey[200],
borderRadius: BorderRadius.circular(8.0),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Center(
child: Text(
'주문 목록',
style: TextStyle(
fontSize: 18.0,
fontWeight: FontWeight.bold,
),
),
),
const SizedBox(height: 16),
const Divider(),
// List of items
Column(
children: orderItems.map((item) {
return Column(
children: [
Row(
mainAxisAlignment:
MainAxisAlignment.spaceBetween,
children: [
Text(item['itemName']),
Text(
'${item['price']} x ${item['itemQuantitySelected']} = ${item['price'] * item['itemQuantitySelected']} 원',
style: const TextStyle(
fontWeight: FontWeight.bold),
),
],
),
const SizedBox(height: 8),
],
);
}).toList(),
),
const SizedBox(height: 16),
const Divider(),
const SizedBox(height: 16),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text(
'총 가격 : $totalPrice 원',
style: const TextStyle(
fontSize: 30.0,
color: Colors.red,
fontWeight: FontWeight.bold,
),
),
],
),
],
),
),
*/