// ==========================================================================
// Project:   WescontrolWeb.Buildings
// Copyright: ©2009 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

/** @class

  (Document your Model here)

  @extends SC.Record
  @version 0.1
*/
WescontrolWeb.Building = SC.Record.extend(
/** @scope WescontrolWeb.Buildings.prototype */ {

	rooms: SC.Record.toMany("WescontrolWeb.Room", {
		inverse: "building", isMaster: NO
	})

}) ;
