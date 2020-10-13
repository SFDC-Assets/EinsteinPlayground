import { LightningElement, wire } from 'lwc';
import getPackageVersion from '@salesforce/apex/Einstein_PlaygroundController.getPackageVersion';

export default class EinsteinPlaygroundIntroductionLwc extends LightningElement {

	@wire(getPackageVersion) packageVersion;

}