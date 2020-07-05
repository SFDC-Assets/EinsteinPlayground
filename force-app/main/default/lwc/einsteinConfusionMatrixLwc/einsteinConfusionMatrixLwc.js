import { LightningElement, api } from 'lwc';

export default class EinsteinConfusionMatrixLwc extends LightningElement {
	@api matrix;
	
	testdata =[
		{
			"key": 0,
			"value": 0,
			"isPrime": false,
			"expected": "Password Help",
			"predicted": "Order Change",
			"examples": [],
			"class": "good"
		},
		{
			"key": 1,
			"value": 1,
			"isPrime": false,
			"expected": "Password Help",
			"predicted": "Sales Opportunity",
			"examples": [],
			"class": "bad"
		},
		{
			"key": 2,
			"value": 0,
			"isPrime": false,
			"expected": "Password Help",
			"predicted": "Billing",
			"examples": [],
			"class": "good"
		},
		{
			"key": 3,
			"value": 0,
			"isPrime": false,
			"expected": "Password Help",
			"predicted": "Shipping Info",
			"examples": [],
			"class": "good"
		},
		{
			"key": 4,
			"value": 6,
			"isPrime": true,
			"expected": "Password Help",
			"predicted": "Password Help",
			"examples": [],
			"class": "prime"
		}
	];

}