import { LightningElement, api } from 'lwc';

export default class EinsteinNerDataTableLwc extends LightningElement {
    tableData = [];
	columns = [
		{ label: 'Label', fieldName: 'label', sortable: true, hideDefaultActions: true },
		{ label: 'Token', fieldName: 'token', type: 'string',sortable: true, hideDefaultActions: true },
		{ label: 'Probability (%)', fieldName: 'probability', type: 'percent',sortable: true, hideDefaultActions: true } 
	];
	defaultSortDirection = "asc";
	sortDirection = "asc";
	sortedBy;
	_probabilities;


	@api get probabilities() {
		return this._probabilities;
	};

	set probabilities(value) {
		console.log('set probabilities', JSON.parse(JSON.stringify(value)));
		this._probabilities = value;

		let self = this;
		if (value && value.length > 0) {
			var probs = JSON.parse(JSON.stringify(value));
			var localData = [];
			probs.forEach(function (item, index) {
				var newItem = {};
				newItem.index = index;
				newItem.label = item.label;
				newItem.probability = item.probability * 100;
				newItem.token = item.token;

				localData.push(newItem);
			})

			this.tableData = localData;

			// presort by token
			this.onHandleSort({ detail: { fieldName: 'token', sortDirection: 'asc' } });
		}
	}

	hasRendered;

	renderedCallback() {
		if (!this.hasRendered) {
			this.hasRendered = true;
		}
	}
	// Used to sort the columns
	sortBy(field, reverse, primer) {
	const key = primer
		? function (x) {
			return primer(x[field]);
		}
		: function (x) {
			return x[field];
		};

		return function (a, b) {
			a = key(a);
			b = key(b);
			return reverse * ((a > b) - (b > a));
		};
	}

	onHandleSort(event) {
		const { fieldName: sortedBy, sortDirection } = event.detail;
		const cloneData = [...this.tableData];

		cloneData.sort(
			this.sortBy(sortedBy, sortDirection === "asc" ? 1 : -1)
		);
		this.tableData = cloneData;
		this.sortDirection = sortDirection;
		this.sortedBy = sortedBy;
	}

	showDetails(event) {
		console.log('showDetails');

		const selectedEvent = new CustomEvent('selected', {detail: event.currentTarget.getAttribute('data-label')});
		this.dispatchEvent(selectedEvent);
	}
}