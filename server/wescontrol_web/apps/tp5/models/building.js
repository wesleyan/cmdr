// ==========================================================================
// Project:   Tp5.Building
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

/** @class

  (Document your Model here)

  @extends SC.Record
  @version 0.1
*/
Tp5.Building = SC.Record.extend(
/** @scope Tp5.Building.prototype */ {
	rooms: SC.Record.toMany("WescontrolWeb.Room", {
		inverse: "building", isMaster: NO
	})
});
