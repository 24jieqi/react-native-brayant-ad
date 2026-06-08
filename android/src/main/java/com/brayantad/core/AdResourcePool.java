package com.brayantad.core;

import android.view.View;
import android.view.ViewGroup;

import com.bytedance.sdk.openadsdk.CSJSplashAd;
import com.bytedance.sdk.openadsdk.TTNativeExpressAd;

import java.util.Iterator;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

public final class AdResourcePool {
  private static final long DEFAULT_TTL_MS = 5 * 60 * 1000L;
  private static final Map<String, Entry> ENTRIES = new ConcurrentHashMap<>();

  private AdResourcePool() {}

  public static final class Entry {
    public final String token;
    public final String requestId;
    public final String format;
    public final String slotId;
    public final int width;
    public final int height;
    public final long expiresAt;
    public final Object resource;

    private Entry(
      String token,
      String requestId,
      String format,
      String slotId,
      int width,
      int height,
      long expiresAt,
      Object resource
    ) {
      this.token = token;
      this.requestId = requestId;
      this.format = format;
      this.slotId = slotId;
      this.width = width;
      this.height = height;
      this.expiresAt = expiresAt;
      this.resource = resource;
    }
  }

  public static synchronized Entry put(
    String requestId,
    String format,
    String slotId,
    int width,
    int height,
    Object resource
  ) {
    cleanupExpired();
    String token = UUID.randomUUID().toString();
    Entry entry = new Entry(
      token,
      requestId,
      format,
      slotId,
      width,
      height,
      System.currentTimeMillis() + DEFAULT_TTL_MS,
      resource
    );
    ENTRIES.put(token, entry);
    return entry;
  }

  public static synchronized Entry consume(
    String token,
    String format,
    String slotId,
    int width,
    int height
  ) {
    cleanupExpired();
    if (token == null || token.isEmpty()) {
      return null;
    }

    Entry entry = ENTRIES.remove(token);
    if (entry == null) {
      return null;
    }

    boolean matches =
      entry.format.equals(format) &&
      entry.slotId.equals(slotId) &&
      (width <= 0 || entry.width == width) &&
      (height <= 0 || entry.height == height);
    if (!matches) {
      destroy(entry.resource);
      return null;
    }
    return entry;
  }

  public static synchronized void discard(String token) {
    Entry entry = ENTRIES.remove(token);
    if (entry != null) {
      destroy(entry.resource);
    }
  }

  private static void cleanupExpired() {
    long now = System.currentTimeMillis();
    Iterator<Map.Entry<String, Entry>> iterator = ENTRIES.entrySet().iterator();
    while (iterator.hasNext()) {
      Map.Entry<String, Entry> item = iterator.next();
      if (item.getValue().expiresAt <= now) {
        destroy(item.getValue().resource);
        iterator.remove();
      }
    }
  }

  private static void destroy(Object resource) {
    if (resource instanceof TTNativeExpressAd) {
      ((TTNativeExpressAd) resource).destroy();
    } else if (resource instanceof CSJSplashAd) {
      View splashView = ((CSJSplashAd) resource).getSplashView();
      if (splashView != null && splashView.getParent() instanceof ViewGroup) {
        ((ViewGroup) splashView.getParent()).removeView(splashView);
      }
    }
  }
}
