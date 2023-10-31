# Einstein Vision and Language Model Builder (aka the Einstein Playground) *(EinsteinPlayground)*

<!-- 
    This should be identical to the repository name/project name, or a relevant title, with the repo name in the italicized paranthesis. The repo name should be in this title is what I'm gettin at here.
-->

[![Salesforce API v48.0](https://img.shields.io/badge/Salesforce%20API-v48.0-blue.svg)]()
[![Lightning Experience Required](https://img.shields.io/badge/Lightning%20Experience-Required-informational.svg)]()
[![User License Platform](https://img.shields.io/badge/User%20License-Platform-032e61.svg)]()
[![Apex Test Coverage 76](https://img.shields.io/badge/Apex%20Test%20Coverage-76-orange.svg)]()


<!-- 
    Badges
    Salesforce badges
        Salesforce API : Version Number
        Lightning Experience : Required / Not Required (Optional, unless using LWC/Aura)
        User License: Sales / Service / Communities / Platform / None (Optional)
        Apex Code Coverage: % 100 green, >75 orange, <75 red (Required if including Apex)
-->    
This is the code repository for the world famous Einstein Vision and Language Model Builder package, also known affectionately as "The Einstein Playground".  

The Einstein Vision and Language Model Builder is a UI layered on top of Einstein’s integrated REST APIs for Einstein .  It enables you to more quickly upload datasets, train deep learning models and test the performance of those models through an easy-to-use GUI.  

If you simply want to install and use the Playground in your org, bop over to the [AppExchange listing](https://sfdc.co/EinsteinModelBuilder).  This will give you the opportunity to install the latest version of the managed package in your org and get started in minutes.  Seriously.  This is the easiest way to go.

If, however, you are looking for code examples of how to work with the Einstein.ai services, need to install an unmanaged version of the Playground, or are dying to propose some additions/extensions/fixes to the Playground, then you are in the right place.

<!-- Longform description. No title here. The quote I stole to define this from the template is - 
* "This should describe your module in broad terms, generally in just a few paragraphs; more detail of the module's routines or methods, lengthy code examples, or other in-depth material should be given in subsequent sections.
Ideally, someone who's slightly familiar with your module should be able to refresh their memory without hitting "page down". As your reader continues through the document, they should receive a progressively greater amount of knowledge." - Kirrily "Skud" Robert, perlmodstyle
-->

## Table of Contents
- [Einstein Vision and Language Model Builder (aka the Einstein Playground) *(EinsteinPlayground)*](#einstein-vision-and-language-model-builder-aka-the-einstein-playground-einsteinplayground)
	- [Table of Contents](#table-of-contents)
	- [Background](#background)
	- [Install](#install)
		- [Salesforce DX - new scratch org](#salesforce-dx---new-scratch-org)
		- [Salesforce DX - deploy to an org from your hub](#salesforce-dx---deploy-to-an-org-from-your-hub)
		- [Salesforce DX - deploy into developer edition or production org](#salesforce-dx---deploy-into-developer-edition-or-production-org)
		- [Dependencies](#dependencies)
	- [Usage](#usage)
	- [Related Projects](#related-projects)
	- [Maintainers](#maintainers)
	- [Thanks](#thanks)
	- [Contributing](#contributing)
<!-- Optional if doc is less than 100 lines total 
    Link to all sections, start with the next one, don't include anything above. Capture all ## headings, optional to get ### and ####, you do you.
-->

## Background

The Einstein Vision and Language services provide REST API services to developers who want to add AI services into their custom applications - either on or off Salesforce Core.  These are really powerful services, but being developer services, you have to either write custom code or use an HTTP request tool like cURL or Postman to get started.

Enter the Playground.  The Playground really provides four capabilities:
* A User Interface, based on Salesforce Lightning Web Components, that enables a user to upload datasets, train models, test predictions, and evaluat the model performance
* Apex "wrapper" code that manages all the complexities of working with the Einstein.ai services such as constructing the JWT token, getting access tokens, refreshing tokens, etc. Global Apex class methods are provided to make predictions which greatly reduces the amount of custom code you need to write.
* Invocable Apex methods available to Process Builder and Flows to easily add predictions on unstructured text or images to your applications with no code.
* Lightning components that can be added to Lightning Record Pages or App Pages to add AI prediction capability to your UI.

There are actually two variants of the Playground - Managed and Unmanaged - contained on two Git branches - master and unmanaged.  The master branch includes all the namespace stuff necessary to create a managed package.  The unmanaged branch is the same code, just not set up with a namespace and not meant to be in a managed package.  
   
The DX project on the `master` branch is already configured to do development work on the managed package, includeing configuration for the `einsteinplay` namespace.  You will need to configure your DevHub to register the `einsteinplay` namespace.

If you just want access to the unmanaged code, switch to the `unmanaged` branch.  You can push the code into a Scratch Org or convert it and use the mdapi to deploy it to a Dev Org.


## Install

Again, if what you need is any of the four things listed above, then go to the [AppExchange listing](https://sfdc.co/EinsteinModelBuilder), install the latest version of the managed package, and be on your merry way.  If you need access to this source code, then read on.

### Salesforce DX - new scratch org

Clone the repo to your local file system.

```
git clone https://github.com/dschultz-mo/EinsteinPlayground
```

run the init.sh script, passing an alias name for your new scratch org
```
./init.sh yourScratchOrgAlias
```

### Salesforce DX - deploy into developer edition or production org

You can use the Salesforce CLI to deploy the source into a regular Salesforce org using the Metatdata API.

Authenticate against the deployment org
```
sfdx force:auth:web:login -a yourOrgAlias
```

Create an output directory for the to be converted source
```
mkdir mdapi
```

Convert the source from Salesforce DX format to Metatdata API format
```
sfdx force:source:convert -r force-app -d mdapi
```

Deploy the source
```
sfdx force:mdapi:deploy -d mdapi -u yourOrgAlias
```

### Dependencies
There are no external dependencies.  All JavaScript libraries required are included as static resources.

## Usage
To use the Playground GUI, invocable Apex, global Apex or Lightning components, see the [Einstein Vision and Language Model Builder User Guide](http://sfdc.co/EinsteinModelBuilderUsersGuide).

Version updates can be found in the [Einstein Vision and Language Model Builder Release Notes](http://sfdc.co/EinsteinModelBuilderReleaseNotes).

## Related Projects
If you create any projects that depend on the Invocable Apex or Global Apex, let us know and we will call them out here!

## Maintainers
<!--Small list of folk in charge, not everyone involved.-->
[Monojit Banerjee](https://github.com/MonojitBanerjee)

## Thanks
<!--Don't be a jerk thank those who helped you-->
Thanks to [Mike Brosseau](https://github/mbrosseau), [René Winkelmeyer](https://github.com/muenzpraeger) and all the other nameless pioneers who created countless code repos and snippets that lead to this project over the years. Also thanks to our previous maintainers.
[Dennis Schultz](https://github.com/dschultz-mo)
[Surabhi Ravishankar](https://github.com/surabhiiyer)

## Contributing
<!--Give instructions on how to contribute to this repository. Where do I ask questions? Do you accept PRs? What are the requirements to contribute? Don't be a jerk. Use issues if you can.-->
The Playground is updated and enhanced on a time-available basis.  We would love to hear your ideas for what else could be done.  Feel free to submit Issues on this repo.

But better still, we would love to see your contributions!  Reach out if you have some ideas.  If you are a coder, fork it and send a pull request.
