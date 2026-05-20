import frappe
from frappe.model.document import Document


class BLEDeviceProtocol(Document):
    def validate(self):
        if self.name_keywords:
            # Normalize to lowercase, comma-separated
            keywords = [k.strip().lower() for k in self.name_keywords.split(",")]
            self.name_keywords = ",".join(keywords)

    def to_mobile_dict(self):
        """Serialize this protocol to a dict consumable by the Flutter app."""
        return {
            "name": self.protocol_name,
            "device_types": [self.device_type],
            "delivery_mode": self.delivery_mode,
            "parser_type": self.parser_type,
            "is_active": bool(self.is_active),
            "name_keywords": self._parse_keywords(),
            "service_uuids": [row.service_uuid for row in self.service_uuids],
            "measurement_chars": [
                {"service_uuid": row.service_uuid, "char_uuid": row.char_uuid}
                for row in self.characteristics
                if row.char_type == "Measurement"
            ],
            "control_chars": [
                {"service_uuid": row.service_uuid, "char_uuid": row.char_uuid}
                for row in self.characteristics
                if row.char_type == "Control"
            ],
            "init_sequence": [
                {
                    "service_uuid": row.service_uuid,
                    "char_uuid": row.char_uuid,
                    "value": [int(b, 16) for b in row.value_hex.split()],
                }
                for row in self.init_sequence
            ],
        }

    def _parse_keywords(self):
        if not self.name_keywords:
            return []
        return [k.strip() for k in self.name_keywords.split(",") if k.strip()]
