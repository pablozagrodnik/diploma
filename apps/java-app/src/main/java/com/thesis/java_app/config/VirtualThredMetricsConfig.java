package com.thesis.java_app.config;

import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jdk.management.VirtualThreadSchedulerMXBean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.lang.management.ManagementFactory;
import java.util.concurrent.atomic.AtomicInteger;

@Configuration
@Order(Ordered.HIGHEST_PRECEDENCE)
public class VirtualThredMetricsConfig extends OncePerRequestFilter {

    private final AtomicInteger activeVirtualThreads = new AtomicInteger(0);

    public VirtualThredMetricsConfig(MeterRegistry registry) {
        Gauge.builder("jvm_threads_virtual_active", activeVirtualThreads, AtomicInteger::get)
                .description("Active Virtual Threads")
                .register(registry);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        if (Thread.currentThread().isVirtual()) {
            activeVirtualThreads.incrementAndGet();
            try {
                filterChain.doFilter(request, response);
            } finally {
                activeVirtualThreads.decrementAndGet();
            }
        } else {
            filterChain.doFilter(request, response);
        }
    }
}
