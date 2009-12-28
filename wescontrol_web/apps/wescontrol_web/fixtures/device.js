// ==========================================================================
// Project:   WescontrolWeb.Device Fixtures
// Copyright: ©2009 My Company, Inc.
// ==========================================================================
/*globals WescontrolWeb */

sc_require('models/device');

WescontrolWeb.Device.FIXTURES = [
	{
		guid: 1,
		name: 'Projector',
		room: 3,
		state_vars: {
			power: {
				type: 'boolean',
				editable: true,
				state: true,
				displayOrder: 1
			},
			input: {
				type: 'option',
				options: [
					'SVID',
					'VID',
					'COMP1',
					'COMP2',
					'COMP3'
				],
				editable: true,
				state: "SVID",
				displayOrder: 2
			},
			brightness: {
				type: 'percentage',
				editable: true,
				state: 0.8,
				displayOrder: 3
			},
			videoMute: {
				type: 'boolean',
				editable: true,
				state: false,
				displayOrder: 4
			},
			lampRemaining: {
				type: 'string',
				editable: false,
				state: "300 hours",
				displayOrder: 6
			},
			onTime: {
				type: 'string',
				editable: false,
				state: "5 hours",
				displayOrder: 5
			},
			totalUsage: {
				type: 'string',
				editable: false,
				state: "1001 hours"
			}
		}
	},
	{
		guid: 2,
		name: "Extron",
		room: 3,
		state_vars: {
			input: {
				type: 'option',
				editable: true,
				options: [
					"1 (PC)",
					"2 (Mac)",
					"3 (Laptop)",
					"4 (DVD/VCR)"
				],
				state: "4 (DVD/VCR)",
				displayOrder: 1
			},
			volume: {
				type: 'percentage',
				editable: true,
				state: 0.64,
				displayOrder: 2
			},
			clipping: {
				type: "boolean",
				editable: false,
				state: false,
				displayOrder: 3
			}
		}
	}

];
