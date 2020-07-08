import { LightningElement, api } from 'lwc';

export default class EinsteinConfusionMatrixElementLwc extends LightningElement {

	@api item;

	tooltip = false;

	showToolTip() {
		this.tooltip = true;
	}
	
    hideToolTip() {
		this.tooltip = false;
	}

	get containerClass() {
		return "slds-text-align_center " + this.item.class;
	}

	get anchorClass() {
		return "anchor slds-text-align_center " + this.item.class;
	}

	get hoverText() {
		let divOpen = '<div style="font-weight: bold;font-style: italic;color: ghostwhite;">';
		let otherDivOpen = '<div style="color: gray">';
		let divClose = '</div>';
		if (this.item.expected === this.item.predicted){
			return otherDivOpen + 'Correctly Predicted as ' + divClose + divOpen + this.item.expected + divClose;

		} else {
			return otherDivOpen + 'Prediction is ' + divClose + divOpen + this.item.predicted + divClose + 
			otherDivOpen + 'but should have been ' + divClose + divOpen + this.item.expected + divClose;
		}
	}
}