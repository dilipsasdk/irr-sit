# SAS Salesforce

This repository contains the source code for SAS implementation of Salesforce.

## Development process

SAS Salesforce is setup with Scratch Orgs, VS Code (or your favorite editor), using the Org Development model.

### Getting started

Development is possible also with other editors, but support seems to be best for VS Code. Most importantly,
there's the Salesforce Extension Pack that offers very handy UI to the Salesforce CLI. There's also a bunch of
other helpful extensions and tools, but these will get you started.

#### Install

1. [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli)
2. [VS Code](https://code.visualstudio.com)
3. [Salesforce Extension Pack for VS Code](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode)
4. [SFDMU plugin](https://help.sfdmu.com/plugin-basics/basic-usage/installation)

#### In Github

Add .ssh keys to https://github.com/settings/keys

#### In VS Code

Run the following commands from the Command Palette (Mac: ⇧⌘P, Windows: Ctrl + Shift + p):

Authorize SF CLI to access the organization:

Run `SFDX: Authorize a Dev Hub` Might take a few tries to get working. Something caused by the AD auth, probably.

To set up new Scratch Org with some additional features (pre-assigned permissions, baseline integrations), run `scripts/create-org` in your terminal.

You can also use the SF CLI Commands to create the org and manually push the code if you don't want
the integrations or mock data.

##### Useful commands for the SF CLI

`SFDX: Create a default scratch org...` to create a new scratch org to work in.
`SFDX: Push Source to Default Scratch Org` to push current branch's code to the scratch org.

##### Setting up connection to TEDS [Optional, useful when working on Booking-related features]

After it has finished go to Named Credentials and edit the SAS_APIM_TEDS_FCS one.
Click Save without modifying anything to start the Authentication flow. You will be redirected to a Visualforce page where you can enter the authentication info:

- Username: client id
- Password: client secret
- Additional Param 1: TEDS subscription key
- Additional Param 2: api://SAS.TEDS.API.TEST

### Local development

1. Create a branch from `support/master` for features and `master` for hotfixes.
2. Run `scripts/create-org` in terminal to create a new scratch org to work in.
3. Run `SFDX: Push Source to Default Scratch Org` to push updated code to the scratch org.
4. Make the changes you need to do in the scratch org.
5. Run `SFDX: Pull Source from Default Scratch Org`
6. Commit, Push and PR.

## Conventions

We use Prettier to format all LWC and Apex code.
Setup instructions can be found [here](https://developer.salesforce.com/tools/vscode/en/user-guide/prettier)

Listviews, email templates, entitlement procesess, dashboards and reports are all managed only in production.

All naming, whether it is function, classes, modules or something else, should be consistent, simple and understandable to business users. A single concept should never have more than one name in the codebase. The domain model outlined in Confluence has been created to help keeping things consistent and clear.

We have a small number of people operating and further developing the service. This means that we have to avoid production incidents, reintroducing bugs, manual operational work, and all other toil. Otherwise the pace of new feature development slows to a crawl. Because of this we should automate anything that is reasonable to automate: deployments, alerting, code formatting, testing...

## Structure

### Overview

All new code should be built utilising the structure outlined by the [FFLib Apex Common](https://github.com/apex-enterprise-patterns/fflib-apex-common)
library. There is a lot of existing code that does not conform to this structure, but going forward all new code should
be structured in the same way.

The codebase consists of several layers and major parts: Controllers, Selectors, Services and Domain classes.

In addition to this, it is split between the IRR application and the Service application. These don't have a 100% clear-cut line between them, as
service application depends on some data from the IRR application.

### Controllers

Controllers provide entry points to application logic for outside parts, primarily LWC components. Controllers themselves should have minimal logic, and
only make requests to the service layer to perform actions in the application, selectors to retrieve data to be displayed and perform (de)serialising to make
data better formatted for their callers.

### Selectors

Selectors provide a way of querying objects within Salesforce. There should be no SOQL in the application outside of these classes. They let
us concentrate all database querying logic to a single place. Selectors should have no side effects and be idempotent.

### Services

Services create the primary interface of the application. They provide methods for modifying data, connections to external services, and other interactivity.
These should be written in a way that makes them easily callable from anything from invocable methods to the REST API and triggers.

Transaction management, including e.g. unit of work commits, should happen primarily at this level.

### Domain classes

Most domain concepts have been split into two different classes. E.g. for flights we have the classes `Flight` and `Flights`.

Instances of the class with a _singular_ name represent individual database rows. They offer direct access to read and modify individual
fields of the given row and provide most business rules. E.g. instance methods for a flight include `isOperatedByStarAlliance` and `getFlightDistancesInMeters`.
These classes also include e.g. mappings between picklist values and enums whenever those are deemed useful.

Instances of the class with a _plural_ name represent a collection of rows on which operations can be done. E.g. for `Settlements` we have instance methods such as `markAsDone`.
These classes are also trigger handlers for the given SF object.

Updating domain objects should happen primarily through these classes, but they should never make any SOQL queries or external callouts.

### Dependency injection

To support testing selectors, services and domain class dependencies are provided through dependency injection with the
[SAS_Service_Application](sas-core/main/default/classes/SAS_Service_Application.cls) class.

This allows for easy mocking by simply replacing the implementations provided by the class.

### Triggers

Trigger logic is handled by the domain classes. This means that triggers themselves should be barebones classes that only create
an instance of the correct domain class. E.g. for accounts we have the AccountTrigger.trigger file,
that delegates handling the trigger actions to Accounts.cls, which extends fflib_SObjectDomain.cls
base class for all triggers.

## Testing

The service side of the application has primarily two kinds of tests: _integration tests_ and _unit tests_. Unit tests
should test a single class or another similar unit, and mock all complex dependencies. Integration tests should
test end-to-end functionality, starting e.g. from LWC controllers. Integration tests should still mock external
service dependencies, such as the TEDS integration, but should do all internal SF actions, such as DB reads and inserts.

We have a generic mock for APIM, APIMMock, available in the `tests/mocks` folder. To handle tests which call DML functions and/or make callouts the following structure works pretty well:

```
@IsTest
public static void insertingAnAccountShouldFetchTPProducts() {
  // Do prep work here.

  // Set the mock. After his point all callouts are mocked.
  Test.setMock(HttpCalloutMock.class, new APIMMock());

  // Test block. All DML operations and callouts within are collected and executed sequentially
  // at the Test.stopTest(); line.
  Test.startTest();

  Account newAccount = new Account(
    FirstName = 'Test',
    LastName = 'Account'
  );
  insert newAccount;
  Test.stopTest();

  // Perform asserts after the Test.stopTest() line.
  System.assert(
    bookingsFromDB.size() > 0,
    'There should be a new booking related to the account'
  );
}
```

See [Performing DML Operations and Mock Callouts](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_restful_http_testing_dml.htm) and [Testing HTTP Callouts by Implementing the HttpCalloutMock Interface](https://developer.salesforce.com/docs/atlas.en-us.234.0.apexcode.meta/apexcode/apex_classes_restful_http_testing_httpcalloutmock.htm) in Salesforce docs for more details.

When in a hurry, focus on creating a small number of quality integration tests which cover a sufficient number of execution paths.
Unit tests are nice to have, but are less useful. They are great in ensuring no regressions happen around discovered bugs, or complex
business logic, but otherwise maintenace burden is often pretty high.
