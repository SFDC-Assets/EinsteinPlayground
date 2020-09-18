import { LightningElement, api } from 'lwc';

export default class EinsteinOcrDataTableLwc extends LightningElement {
	tableData = [];
	columns = [
		{ label: 'Label', fieldName: 'label', sortable: true, hideDefaultActions: true },
		{ label: 'Min X', fieldName: 'minX', type: 'number',sortable: true, hideDefaultActions: true },
		{ label: 'Max X', fieldName: 'maxX', type: 'number',sortable: true, hideDefaultActions: true },
		{ label: 'Min Y', fieldName: 'minY', type: 'number',sortable: true, hideDefaultActions: true },
		{ label: 'Max Y', fieldName: 'maxY', type: 'number', sortable: true, hideDefaultActions: true },
		// Center alignment is a work-around for a datatable bug that overlays the scroll bar on top of the rightmost column.
		{ label: 'Page', fieldName: 'pageNumber', type: 'number', sortable: true, hideDefaultActions: false, cellAttributes: { alignment: 'center' } }
	];
	defaultSortDirection = "asc";
	sortDirection = "asc";
	sortedBy;
	_probabilities;


	@api get probabilities() {
		return this._probabilities;
	};

	set probabilities(value) {
		this._probabilities = value;

		let self = this;
		if (value && value.length > 0) {
			var probs = JSON.parse(JSON.stringify(value));
			var localData = [];
			probs.forEach(function (item, index) {
				var newItem = {};
				newItem.index = index;
				if (item.attributes.key) {
					// construct something useful for OCR Forms
					newItem.label = item.attributes.key.text + ' - ' + item.attributes.value.text;
				} else {
					newItem.label = item.label;
				}
				newItem.probability = item.probability;
				newItem.minX = item.boundingBox.minX;
				newItem.maxX = item.boundingBox.maxX;
				newItem.minY = item.boundingBox.minY;
				newItem.maxY = item.boundingBox.maxY;
				// Work around temporary lack of pageNumber attribute
				newItem.pageNumber = (item.attributes.pageNumber ? item.attributes.pageNumber : '0');

				localData.push(newItem);
			})

			this.tableData = localData;

			// presort by page, then minX, then maxY, then page
			this.onHandleSort({ detail: { fieldName: 'minX', sortDirection: 'asc' } });
			this.onHandleSort({ detail: { fieldName: 'maxY', sortDirection: 'asc' } });
			this.onHandleSort({ detail: { fieldName: 'pageNumber', sortDirection: 'asc' } });
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
}