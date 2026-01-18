export const getImageUrl = (path: string | null | undefined): string => {
    // Return placeholder if no path
    if (!path) {
        console.warn('getImageUrl: No path provided');
        return 'https://via.placeholder.com/300x200?text=No+Image';
    }

    // If already a full URL, return as is
    if (path.startsWith('http://') || path.startsWith('https://')) {
        return path;
    }

    // Clean up the path: remove leading slashes
    let cleanPath = path.trim();

    // Remove leading slash if present
    if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
    }

    // Construct the URL using the Nginx proxy path
    // Path from database already includes 'products/{product-id}/{filename}'
    // So we just need to add /storage/ prefix
    const BASE_URL = '/storage';
    const imageUrl = `${BASE_URL}/${cleanPath}`;

    // Log for debugging in development mode
    if (import.meta.env.DEV) {
        console.log('Image URL:', { original: path, cleaned: cleanPath, final: imageUrl });
    }

    return imageUrl;
};
