// ==========================================================================
// Project:   Tp5.Source Fixtures
// Copyright: ©2010 My Company, Inc.
// ==========================================================================
/*globals Tp5 */

sc_require('models/source');

Tp5.Source.FIXTURES = [
	
	{ 
		guid: 1,
		name: "Mac",
		image: {
			source: "mac.png",
			width: 115,
			height: 54
		},
		input: {
			projector: "RGB1",
			switcher: "1"
		}
	},
	{ 
		guid: 2,
		name: "PC",
		image: {
			source: "computer.svg",
			width: 95,
			height: 95
		},
		input: {
			projector: "RGB1",
			switcher: "4"
		}
	},
	{ 
		guid: 3,
		name: "Laptop",
		image: {
			source: "laptop.svg",
			width: 80,
			height: 73
		},
		input: {
			projector: "RGB1",
			switcher: "2"
		}
	},
	{ 
		guid: 4,
		name: "DVD",
		image: {
			source: "DVD.png",
			width: 70,
			height: 70
		},
		input: {
			projector: "VIDEO",
			switcher: "3"
		}
	}
];

