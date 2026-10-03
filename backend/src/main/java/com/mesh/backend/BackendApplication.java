package com.mesh.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.util.TimeZone;

@SpringBootApplication
public class BackendApplication {

	static {
		// Java/Windows report the Indian timezone using the old name "Asia/Calcutta",
		// but PostgreSQL only accepts the modern name "Asia/Kolkata" and rejects the
		// connection otherwise. Setting the system property alone isn't reliable because
		// logging frameworks (Logback) can cache the timezone before that property is read.
		// TimeZone.setDefault() overwrites the JVM's cached value directly, which always works.
		TimeZone.setDefault(TimeZone.getTimeZone("Asia/Kolkata"));
	}

	public static void main(String[] args) {
		SpringApplication.run(BackendApplication.class, args);
	}
}