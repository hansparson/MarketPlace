export const formatRelativeTime = (date: string | Date | number): string => {
    if (!date) return '';
    const now = new Date();
    const past = new Date(date);

    // Robustness: handle invalid dates
    if (isNaN(past.getTime())) return '';

    const diffInSeconds = Math.floor((now.getTime() - past.getTime()) / 1000);

    if (diffInSeconds < 0) return 'baru saja';

    if (diffInSeconds < 60) {
        return `${diffInSeconds} detik lalu`;
    }

    const diffInMinutes = Math.floor(diffInSeconds / 60);
    if (diffInMinutes < 60) {
        return `${diffInMinutes} menit lalu`;
    }

    const diffInHours = Math.floor(diffInMinutes / 60);
    if (diffInHours < 24) {
        return `${diffInHours} jam lalu`;
    }

    const diffInDays = Math.floor(diffInHours / 24);
    if (diffInDays < 31) {
        return `${diffInDays} hari lalu`;
    }

    const diffInMonths = Math.floor(diffInDays / 30);
    if (diffInMonths < 12) {
        return `${diffInMonths} bulan lalu`;
    }

    const diffInYears = Math.floor(diffInMonths / 12);
    return `${diffInYears} tahun lalu`;
};
