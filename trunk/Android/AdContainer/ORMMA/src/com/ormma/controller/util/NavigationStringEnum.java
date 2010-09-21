package com.ormma.controller.util;

public enum NavigationStringEnum {

	NONE("none"), CLOSE("close"), BACK("back"), FORWARD("forward"), REFRESH("refresh");

	private String text;

	NavigationStringEnum(String text) {
		this.text = text;
	}

	public String getText() {
		return this.text;
	}

	public static NavigationStringEnum fromString(String text) {
		if (text != null) {
			for (NavigationStringEnum b : NavigationStringEnum.values()) {
				if (text.equalsIgnoreCase(b.text)) {
					return b;
				}
			}
		}
		return null;
	}
}
