package com.ticketly.booking.domain;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

/**
 * Generic JPA attribute converter that maps an entity field to a {@code text} column holding JSON,
 * backed by Jackson. Used for the {@code fare} and {@code price} snapshots on {@link Booking}
 * (deliberately not Hibernate's {@code @JdbcTypeCode(JSON)} support, so the columns stay portable
 * plain text).
 *
 * @param <T> mapped type
 */
@Converter
public abstract class JsonColumnConverter<T> implements AttributeConverter<T, String> {

    private static final ObjectMapper MAPPER = new ObjectMapper().findAndRegisterModules();

    private final Class<T> targetType;

    protected JsonColumnConverter(Class<T> targetType) {
        this.targetType = targetType;
    }

    @Override
    public String convertToDatabaseColumn(T attribute) {
        if (attribute == null) {
            return null;
        }
        try {
            return MAPPER.writeValueAsString(attribute);
        } catch (Exception ex) {
            throw new IllegalStateException("Could not serialize " + targetType.getSimpleName() + " to JSON", ex);
        }
    }

    @Override
    public T convertToEntityAttribute(String dbData) {
        if (dbData == null || dbData.isBlank()) {
            return null;
        }
        try {
            return MAPPER.readValue(dbData, targetType);
        } catch (Exception ex) {
            throw new IllegalStateException("Could not deserialize " + targetType.getSimpleName() + " from JSON", ex);
        }
    }
}
