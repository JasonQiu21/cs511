// Jason Qiu and Jackey Yang
// I pledge my honor that I have abided by the Stevens Honor System.

import java.util.concurrent.Semaphore
Semaphore mutexS = new Semaphore(1)
Semaphore mutexF = new Semaphore(1)
Semaphore studentPermit = new Semaphore(1)
Semaphore facultyPermit = new Semaphore(1)
final int S = 10 // Number of students
final int F = 10 // Number of faculty
final int CM = 3 // Number of cleaning machines
int studentCount = 0
int facultyCount = 0

S. times {
    int id = it
    Thread.start { // Student
        mutexS.acquire()
        studentCount++
        if(studentCount == 1){
            studentPermit.acquire()
        }
        System.out.println("Student entered room")
        mutexS.release()
        

        mutexS.acquire()
        studentCount--
        if(studentCount == 0){
            studentPermit.release()
        }
        System.out.println("Student left room")
        mutexS.release()
    }
}
F.times {
    int id = it
    Thread.start { // Faculty
        mutexF.acquire()
        facultyCount++
        if(facultyCount == 1){
            facultyPermit.acquire()
        }
        System.out.println("Faculty entered room")
        mutexF.release()
        

        mutexF.acquire()
        facultyCount--
        if(facultyCount == 0){
            facultyPermit.release()
        }
        System.out.println("Faculty left room")
        mutexF.release()

    }
}
CM.times {
    int id = it
    Thread.start { // Clean
        while ( true ) {
            studentPermit.acquire()
            facultyPermit.acquire()

            System.out.println("cleaning...")

            studentPermit.release()
            facultyPermit.release()
        }
    }
}