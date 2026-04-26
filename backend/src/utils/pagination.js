/**
 * Helper pagination standardisé
 * Usage: const { page, limit, skip } = parsePagination(req.query);
 */
function parsePagination(query, defaults = {}) {
    const maxLimit = defaults.maxLimit || 50;
    const defaultLimit = defaults.limit || 10;
    const defaultPage = 1;

    let page = parseInt(query.page, 10);
    if (isNaN(page) || page < 1) page = defaultPage;

    let limit = parseInt(query.limit, 10);
    if (isNaN(limit) || limit < 1) limit = defaultLimit;
    if (limit > maxLimit) limit = maxLimit;

    const skip = (page - 1) * limit;

    return { page, limit, skip };
}

/**
 * Formater la réponse pagination standardisée
 */
function formatPagination(page, limit, total) {
    return {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
    };
}

module.exports = { parsePagination, formatPagination };
