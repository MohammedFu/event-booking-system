function getRequestBaseUrl(request) {
  const forwardedProto = request.headers["x-forwarded-proto"];
  const forwardedHost = request.headers["x-forwarded-host"];
  const host = forwardedHost || request.headers.host;
  const protocol = forwardedProto || request.protocol || "http";

  if (host) {
    return `${protocol}://${host}`.replace(/\/$/, "");
  }

  const envBaseUrl = process.env.PUBLIC_BASE_URL || process.env.BASE_URL;
  if (envBaseUrl) {
    return envBaseUrl.replace(/\/$/, "");
  }

  return `${protocol}://${request.hostname}`.replace(/\/$/, "");
}

function normalizeMediaUrl(url, request) {
  if (typeof url !== "string" || !url.trim()) {
    return url;
  }

  const trimmed = url.trim();
  const baseUrl = getRequestBaseUrl(request);

  try {
    const parsed = new URL(trimmed, `${baseUrl}/`);
    const isUploadAsset = parsed.pathname.includes("/uploads/");

    if (!isUploadAsset) {
      return parsed.toString();
    }

    const requestBase = new URL(baseUrl);
    parsed.protocol = requestBase.protocol;
    parsed.host = requestBase.host;
    return parsed.toString();
  } catch (_) {
    return trimmed;
  }
}

function normalizeProviderMedia(provider, request) {
  if (!provider) {
    return provider;
  }

  return {
    ...provider,
    logoUrl: normalizeMediaUrl(provider.logoUrl, request),
    coverUrl: normalizeMediaUrl(provider.coverUrl, request),
  };
}

function normalizeServiceMedia(service, request) {
  if (!service) {
    return service;
  }

  return {
    ...service,
    images: Array.isArray(service.images)
      ? service.images.map((image) => normalizeMediaUrl(image, request))
      : [],
    provider: normalizeProviderMedia(service.provider, request),
  };
}

module.exports = {
  getRequestBaseUrl,
  normalizeMediaUrl,
  normalizeProviderMedia,
  normalizeServiceMedia,
};
