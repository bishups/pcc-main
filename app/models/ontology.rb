module Ontology

  module Enquiry
    module Type
      GENERAL_ENQUIRY               = "General"
      TEACHER_TRAINING_ENQUIRY      = "Teacher Training"
      OTHER_ENQUIRY                 = "Other"

      ALL = [
        GENERAL_ENQUIRY,
        TEACHER_TRAINING_ENQUIRY,
        OTHER_ENQUIRY
      ]
    end
  end

  module Venue
    CAPACITY_SMALL = "Small"
    CAPACITY_MEDIUM = "Medium"
    CAPACITY_LARGE = "Large"

    CAPACITY_ALL = [
      CAPACITY_SMALL, CAPACITY_MEDIUM, CAPACITY_LARGE
    ]

    SLOT_MORNING = "Morning (6am-9am)"
    SLOT_AFTERNOON = "Afternoon (10am-1pm)"
    SLOT_EVENING = "Evening (2pm-5pm)"
    SLOT_NIGHT = "Night (6pm-9pm)"
    SLOT_FULL_DAY = "Full Day"

    SLOT_ALL = [
      SLOT_MORNING, SLOT_AFTERNOON, SLOT_EVENING, SLOT_NIGHT, SLOT_FULL_DAY
    ]
  end

  module Teacher
    STATE_UNKNOWN = "Unknown"
    STATE_AVAILABLE = "Available"
    STATE_UNAVAILABLE = "Not Available"
    STATE_BLOCKED = "Blocked"
    STATE_ASSIGNED = "Assigned"
    STATE_BACKOUT = "Request Back Out"

    STATE_RESERVE = [
      STATE_AVAILABLE, STATE_UNAVAILABLE
    ]

    STATE_BLOCK_ASSIGN = [
      STATE_BLOCKED, STATE_ASSIGNED
    ]

    SLOT_MORNING = "Morning (6am-9am)"
    SLOT_AFTERNOON = "Afternoon (10am-1pm)"
    SLOT_EVENING = "Evening (2pm-5pm)"
    SLOT_NIGHT = "Night (6pm-9pm)"
    SLOT_FULL_DAY = "Full Day"

    SLOT_ALL = [
      SLOT_MORNING, SLOT_AFTERNOON, SLOT_EVENING, SLOT_NIGHT, SLOT_FULL_DAY
    ]
  end

end